Puppet::Type.type(:physical_volume).provide(:lvm) do
    desc "Manages LVM physical volumes"

    commands :pvcreate  => 'pvcreate', :pvdestroy => 'pvdestroy'

    def create
        pvcreate(@resource[:name])
    end

    def destroy
        pvdestroy(@resource[:name])
    end
end
