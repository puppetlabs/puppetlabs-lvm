Puppet::Type.type(:physical_volume).provide(:lvm) do
    desc "Manages LVM physical volumes"

    commands :pvcreate  => 'pvcreate', :pvremove => 'pvremove'

    def create
        pvcreate(@resource[:name])
    end

    def destroy
        pvremove(@resource[:name])
    end

    def exists?
        File.exist?(@resource[:name])
    end

end
