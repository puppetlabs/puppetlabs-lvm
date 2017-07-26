Puppet::Type.type(:physical_volume).provide(:iax) do
    desc "Manages LVM physical volumes"
    #defaultof :operatingsystem => AIX
    #confine :operatingsystem => AIX

    commands :mkdev    => 'mkdev',
             :rmdev    => 'rmdev',
             :lspv     => 'lspv',
             :lsvg     => 'lsvg',
             :varyonvg => 'varyonvg'

    def create
        mkdev('-l', @resource[:name])
    end

    def destroy
        rmdev('-l', @resource[:name])
    end

    def exists?
      # If unless_vg is set we need to see if
      # the volume group exists
      if @resource[:unless_vg]
        begin
          # Check to see if the volume group exists
          # if it does set TRUE else FALSE
          lsvg(@resource[:unless_vg])
          vg_exists = true
        rescue Puppet::ExecutionFailure => e
          Puppet.debug("lsvg of #{resource[:unless_vg]} had an error -> #{e.inspect}")
          # Check to see what the error was and if it was a varyon error
          # attempt to start the vg.
          if e.inspect =~ /Volume group must be varied on; use varyonvg command./
            if varyon_vg(resource[:unless_vg])
              vg_exists = true
            else
              vg_exists = false
            end
          else
            vg_exists = false
          end
        end
      end
      name_aix = fix_name_aix(resource[:name])
      # If vg exists FALSE
      if ! vg_exists
        begin
          # Check to see if the PV already exists
          lspv(name_aix)
        rescue Puppet::ExecutionFailure
          false
        end
      else
       # If the VG exists return true
       true
      end
    end

    def fix_name_aix(name)
        aix = name.split("/")
        return aix[-1]
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
