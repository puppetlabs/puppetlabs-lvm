Puppet::Type.type(:physical_volume).provide(:lvm) do
    desc "Manages LVM physical volumes"

    commands :pvcreate  => 'pvcreate', :pvremove => 'pvremove', :pvs => 'pvs', :vgs => 'vgs'

    def force
      @resource[:force] == :true ? '--force' : nil
    end

    def create
        pvcreate([force, @resource[:name]].compact)
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
          vgs(@resource[:unless_vg])
          vg_exists = true
        rescue Puppet::ExecutionFailure
          vg_exists = false
        end
      end
      # If vg exists FALSE 
      if ! vg_exists
        begin
          # Check to see if the PV already exists
          pvs(@resource[:name])
        rescue Puppet::ExecutionFailure
          false
        end
      else
       # If the VG exists return true
       true
      end
    end

end
