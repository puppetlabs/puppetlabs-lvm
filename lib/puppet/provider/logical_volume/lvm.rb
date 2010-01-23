Puppet::Type.type(:logical_volume).provide :lvm do
    
    desc "Manages LVM logical volumes"
    
    commands :lvcreate => 'lvcreate',
             :lvremove => 'lvremove',
             :lvs      => 'lvs',
             :umount   => 'umount',
             :mount    => 'mount'
    
    confine    :kernel => :linux
    defaultfor :kernel => :linux

    def create
        lvcreate('-n', @resource[:name], '--size', @resource.should(:size), @resource[:volume_group])
    end
    
    def destroy
        lvremove(path)
    end
    
    def exists?
        lvs(@resource[:name])
    end

    # The LV should be unmounted, resized, the filesystem resized,
    # and then the LV be re-mounted.
    def size=(new_size)
        umount(path)
        lvextend('--size', new_size, path)
        # TODO: This is when the filesystem should be resized. -BW
        mount(path)
    end

    def size
        lines = lvs('-o', 'lv_name,vg_name,lv_size', '--separator', ',', @resource[:volume_group])
        lines.each do |line|
            lv, vg, current_size = line.split(',')
            if lv == @resource[:name] && vg == @resource[:volume_group]
                return current_size # TODO: Investigate formats -BW
            end
        end
        nil
    end

    private

    def path
        "/dev/#{@resource[:volume_group]}/#{@resource[:name]}"
    end
    
end
