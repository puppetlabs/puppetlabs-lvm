# frozen_string_literal: true

require_relative '../../../puppet_x/lvm/output'

Puppet::Type.type(:volume_group).provide :lvm do
  desc 'Manages LVM volume groups on Linux'

  confine kernel: :linux

  commands vgcreate: 'vgcreate',
           vgremove: 'vgremove',
           vgs: 'vgs',
           vgextend: 'vgextend',
           vgreduce: 'vgreduce',
           pvs: 'pvs'

  def self.instances
    columns = [
      'vg_name',
    ]
    Puppet_X::LVM::Output.parse(
      'vg_name',
      columns,
      vgs('-o', columns.join(','), *Puppet_X::LVM::Output::ARGS),
    ).map do |vg_name, _|
      new(
        ensure: :present,
        name: vg_name,
      )
    end
  end

  def create
    vgcreate_args = [@resource[:name], *@resource.should(:physical_volumes)]
    extent_args = @resource[:extent_size].nil? ? [] : ['-s', @resource[:extent_size]]

    vgcreate_args.append(*extent_args)

    vgcreate(*vgcreate_args)
  end

  def destroy
    vgremove(@resource[:name])
  end

  def exists?
    vgs('-o', 'vg_name', *Puppet_X::LVM::Output::ARGS, @resource[:name])
  rescue Puppet::ExecutionFailure
    false
  end

  def physical_volumes=(new_volumes = [])
    # Only take action if createonly is false just to be safe
    #  this is really only here to enforce the createonly setting
    #  if something goes wrong in physical_volumes
    return unless @resource[:createonly] == :false

    existing_volumes = physical_volumes
    extraneous = existing_volumes - new_volumes
    extraneous.each { |volume| reduce_with(volume) }
    missing = new_volumes - existing_volumes
    missing.each { |volume| extend_with(volume) }
  end

  def physical_volumes
    if @resource[:createonly] == :false || !vgs('-o', 'vg_name', *Puppet_X::LVM::Output::ARGS, @resource[:name])
      columns = [
        'pv_name',
        'vg_name',
      ]
      Puppet_X::LVM::Output.parse(
        'pv_name',
        columns,
        pvs('-o', 'pv_name,vg_name', *Puppet_X::LVM::Output::ARGS),
        ['vg_name'],
      ).each_with_object([]) do |(pv_name, values), results|
        results << pv_name if values['vg_name'] == @resource[:name]
      end
    else
      # Trick the check by setting the returned value to what is
      #  listed in the puppet catalog
      @resource[:physical_volumes]
    end
  end

  private

  def reduce_with(volume)
    vgreduce(@resource[:name], volume)
  rescue Puppet::ExecutionFailure => e
    raise Puppet::Error, "Could not remove physical volume #{volume} from volume group '#{@resource[:name]}'; this physical volume may " \
        + "be in use and may require a manual data migration (using pvmove) before it can be removed (#{e.message})"
  end

  def extend_with(volume)
    vgextend(@resource[:name], volume)
  rescue Puppet::ExecutionFailure => e
    raise Puppet::Error, "Could not extend volume group '#{@resource[:name]}' with physical volume #{volume} (#{e.message})"
  end
end
