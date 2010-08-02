Puppet::Type.type(:filesystem).provide :lvm do
    desc "Manages filesystem of a logical volume"

    commands :mount => 'mount'

    def create
        mkfs(@resource[:ensure])
    end

    def exists?
        fstype == @resource[:ensure]
    end

    def destroy
        # no-op
    end

    def fstype
        mount('-f', '--guess-fstype', @resource[:name]).strip
    rescue Puppet::ExecutionFailure
        nil
    end

    def mkfs(new_fstype)
        mkfs_params = { "reiserfs" => "-q" }
        mkfs_cmd    = ["mkfs.#{new_fstype}", @resource[:name]]
        
        if mkfs_params[new_fstype]
            command_array << mkfs_params[new_fstype]
        end
        
        execute mkfs_cmd
    end

end
