Puppet::Type.type(:logical_volume).provide :lvm do
    desc "Manages LVM logical volumes"
    
    commands :lvcreate => 'lvcreate',
             :lvremove => 'lvremove',
             :lvs      => 'lvs',
             :umount   => 'umount',
             :mount    => 'mount'
    
    def create
        args = ['-n', @resource[:name]]
        if @resource[:size]
            args.push('--size', @resource[:size])
        end
        args << @resource[:volume_group]
        lvcreate(*args)
    end
    
    def destroy
        lvremove(path)
    end
    
    def exists?
        lvs(@resource[:name])
    end

    private

    def path
        "/dev/#{@resource[:volume_group]}/#{@resource[:name]}"
    end
end
