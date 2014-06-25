Puppet::Type.type(:filesystem).provide :lvm do
    desc 'Manages filesystem of a logical volume'

    commands :blkid => 'blkid'

    def create
        mkfs(@resource[:fs_type])
    end

    def exists?
        fstype != nil
    end

    def destroy
        # no-op
    end

    def fstype
        /TYPE=\"(\S+)\"/.match(blkid(@resource[:name]))[1]
    rescue Puppet::ExecutionFailure
        nil
    end

    def mkfs(fs_type)
        mkfs_params = { 'reiserfs' => '-q' }
        mkfs_cmd    = ["mkfs.#{fs_type}", @resource[:name]]
        
        if mkfs_params[fs_type]
            mkfs_cmd << mkfs_params[fs_type]
        end
        
        if resource[:options]
            mkfs_options = Array.new(resource[:options].split)
            mkfs_cmd << mkfs_options
        end

        execute mkfs_cmd
    end

end
