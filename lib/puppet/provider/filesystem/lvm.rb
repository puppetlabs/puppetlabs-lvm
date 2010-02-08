Puppet::Type.type(:filesystem).provide :lvm do
    desc "Manages LVM volume groups"

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
        execute ["mkfs.#{new_fstype}", @resource[:name]]
    end

end
