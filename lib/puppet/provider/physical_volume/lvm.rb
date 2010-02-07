Puppet::Type.type(:physical_volume).provide(:lvm) do
    desc "Manages LVM physical volumes"

    commands :pvcreate  => 'pvcreate', :pvremove => 'pvremove', :pvs => 'pvs'

    def create
        pvcreate(@resource[:name])
    end

    def destroy
        pvremove(@resource[:name])
    end

    def exists?
        pvs(@resource[:name])
    rescue Puppet::ExecutionFailure
        false
    end

end
