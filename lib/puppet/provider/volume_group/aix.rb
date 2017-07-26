Puppet::Type.type(:volume_group).provide :aix do
    desc "Manages LVM volume groups on AIX"
    #defaultof :operatingsystem => AIX
    #confine :operatingsystem => AIX

    commands :mkvg => 'mkvg',
             :exportvg  => 'exportvg',
             :lsvg      => 'lsvg',
             :extendvg  => 'extendvg',
             :reducevg  => 'reducevg',
             :lspv      => 'lspv',
             :varyonvg  => 'varyonvg',
             :varyoffvg => 'varyoffvg'

    def create
        if @resource[:force_create]
          mkvg('-f', '-y', @resource[:name], *@resource.should(:physical_volumes))
        else
          mkvg('-y', @resource[:name], *@resource.should(:physical_volumes))
        end
    end

    def destroy
        begin
          varyoffvg(@resource[:name])
          exportvg(@resource[:name], *@resource.should(:physical_volumes))
        rescue Puppet::ExecutionFailure => e
          Puppet.debug("exportvg of #{resource[:name]} had an error -> #{e.inspect}")
        end
    end

    def exists?
        begin
          lsvg(@resource[:name])
        rescue Puppet::ExecutionFailure => e
          Puppet.debug("lsvg of #{resource[:name]} had an error -> #{e.inspect}")
          # Check to see what the error was and if it was a varyon error
          # attempt to start the vg.
          if e.inspect =~ /Volume group must be varied on; use varyonvg command./
            if varyon_vg(resource[:name])
              true
            else
              false
            end
          else
            false
          end
        end
    end

    def physical_volumes
        if @resource[:createonly].to_s == "false" || ! lsvg(@resource[:name])
          lines = lspv()
          lines.split(/\n/).grep(/#{@resource[:name]}/).map { |s|
            s.split(/\W+/)[0].strip
          }
        else
          # Trick the check by setting the returned value to what is
          #  listed in the puppet catalog
          @resource[:physical_volumes]
        end
    end

    private

    def reduce_with(volume)
        reducevg('-d', @resource[:name], volume)
    rescue Puppet::ExecutionFailure => detail
        raise Puppet::Error, "Could not remove physical volume #{volume} from volume group '#{@resource[:name]}'; this physical volume may be in use and may require a manual data migration (using pvmove) before it can be removed (#{detail.message})"
    end

    def extend_with(volume)
        extendvg(@resource[:name], volume)
    rescue Puppet::ExecutionFailure => detail
        raise Puppet::Error, "Could not extend volume group '#{@resource[:name]}' with physical volume #{volume} (#{detail.message})"
    end

   def varyon_vg(name)
     # This will try to varyonvg a volume_group
     begin
       output = varyonvg(["#{name}"])
       notice("Volume group exists, 'varyonvg #{name}', VG started!")
       return true
     rescue Puppet::ExecutionFailure => e
       Puppet.debug("#varyon_vg had an error -> #{e.inspect}")
       return false
     end
   end
end
