# frozen_string_literal: true

require_relative '../../../puppet_x/lvm/output'

Puppet::Type.type(:physical_volume).provide(:lvm) do
  desc 'Manages LVM physical volumes on Linux'

  confine kernel: :linux

  commands pvcreate: 'pvcreate', pvremove: 'pvremove', pvs: 'pvs', vgs: 'vgs'

  def self.instances
    get_physical_volumes.map do |physical_volumes_line|
      physical_volumes_properties = get_physical_volume_properties(physical_volumes_line)
      new(physical_volumes_properties)
    end
  end

  def self.instances
    columns = [
      'pv_name',
    ]
    Puppet_X::LVM::Output.parse(
      'pv_name',
      columns,
      pvs('-o', columns.join(','), *Puppet_X::LVM::Output::ARGS),
    ).map do |pv_name, _|
      new(
        ensure: :present,
        name: pv_name,
      )
    end
  end

  def create
    create_physical_volume(@resource[:name])
  end

  def destroy
    pvremove(@resource[:name])
  end

  def exists?
    # If unless_vg is set we need to see if
    # the volume group exists
    if @resource[:unless_vg]
      begin
        # Check to see if the volume group exists
        # if it does set TRUE else FALSE
        vgs('-o', 'vg_name', *Puppet_X::LVM::Output::ARGS, @resource[:unless_vg])
        vg_exists = true
      rescue Puppet::ExecutionFailure
        vg_exists = false
      end
    end
    # If vg exists FALSE
    if vg_exists
      # If the VG exists return true
      true
    else
      begin
        # Check to see if the PV already exists
        pvs('-o', 'pv_name', *Puppet_X::LVM::Output::ARGS, @resource[:name])
      rescue Puppet::ExecutionFailure
        false
      end
    end
  end

  private

  def create_physical_volume(path)
    args = []
    args.push('--force') if @resource[:force] == :true
    args << path
    pvcreate(*args)
  end
end
