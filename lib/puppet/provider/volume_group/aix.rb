Puppet::Type.type(:volume_group).provide :aix do
    desc "Manages LVM volume groups on AIX"

    commands :vgcreate => 'mkvg',
             :vgremove => 'reducevg',
             :vgs      => 'lsvg',
             :vgextend => 'extendvg',
             :vgreduce => 'reducevg',
             :pvs      => 'lspv'

    def create
        vgcreate(@resource[:name], *@resource.should(:physical_volumes))
    end

    def destroy
        vgremove(@resource[:name])
    end

    def exists?
        vgs(@resource[:name])
    rescue Puppet::ExecutionFailure
        false
    end

    def physical_volumes=(new_volumes = [])
        # Only take action if createonly is false just to be safe
        #  this is really only here to enforce the createonly setting
        #  if something goes wrong in physical_volumes
        if @resource[:createonly].to_s == "false"
          existing_volumes = physical_volumes
          extraneous = existing_volumes - new_volumes
          extraneous.each { |volume| reduce_with(volume) }
          missing = new_volumes - existing_volumes
          missing.each { |volume| extend_with(volume) }
        end
    end

    def physical_volumes
        if @resource[:createonly].to_s == "false" || ! vgs(@resource[:name])
          # needs inspection - maybe just a simple lspv is enough
          # lines = pvs('-o', 'pv_name,vg_name', '--separator', ',')
            lines = lspv
          lines.split(/\n/).grep(/#{@resource[:name]}$/).map { |s|
          # what is the result here? list of hdisks (hdisk2,hdisk3,hdiskx)?
          # needs inspection on AIX system.
            s.split(/,/)[0].strip
          }
        else
          # Trick the check by setting the returned value to what is
          #  listed in the puppet catalog
          @resource[:physical_volumes]
        end
    end

    private

    def reduce_with(volume)
        vgreduce(@resource[:name], volume)
    rescue Puppet::ExecutionFailure => detail
        raise Puppet::Error, "Could not remove physical volume #{volume} from volume group '#{@resource[:name]}'; this physical volume may be in use and may require a manual data migration (using pvmove) before it can be removed (#{detail.message})"
    end

    def extend_with(volume)
        vgextend(@resource[:name], volume)
    rescue Puppet::ExecutionFailure => detail
        raise Puppet::Error, "Could not extend volume group '#{@resource[:name]}' with physical volume #{volume} (#{detail.message})"
    end
end
