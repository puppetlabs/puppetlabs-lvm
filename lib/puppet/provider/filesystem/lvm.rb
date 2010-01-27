Puppet::Type.type(:filesystem).provide :lvm do
    desc "Manages LVM volume groups"

    commands :df => 'df'

    def create(new_fstype)
        mkfs(new_fstype)
    end

    def fstype
        info[@resource[:name]]['fstype']
    end

    def mkfs(new_fstype)
        execute ["mkfs.#{new_fstype}", @resource[:name]]
    end

    def info
        fields = %w(fstype size used avail used_percentage mounted)
        df('-h', '-T').split(/\n/)[1..-1].inject({}) do |records, line|
            parts = line.split(/\s+/)
            records[parts.shift] = Hash[*(fields.zip(parts).flatten)]
            records
        end
    end
end
