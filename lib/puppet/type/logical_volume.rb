Puppet::Type.newtype(:logical_volume) do
    @depthfirst = true

    newparam(:name) do
        desc "The name of the logical volume.  This is the unqualified name and will be
            automatically added to the volume group's device path (e.g., '/dev/$vg/$lv')."

        validate do |value|
            if value.include?(File::SEPARATOR)
                raise ArgumentError, "Volume names must be entirely unqualified"
            end
        end
    end

    newparam(:fstype) do
        desc "The filesystem type. Valid values depend on the operating system."
    end

    newparam(:volume_group) do
        desc "The volume group name associated with this logical volume.  This will automatically
            create the volume group, and thus should only be used if this logical volume is likely
            to be the only volume in the volume group."
    end

    newparam(:physical_volumes) do
        desc "The physical volumes to use when creating a volume group.  This is only used when
            creating volume groups."
    end

    newparam(:size) do
        desc "The size of the logical volume.  This value will also be used to size the filesystem."
    end
    
    ensurable

    def generate
        [@filesystem, @volume_group].compact
    end

    def initialize(*args)
        super
        @filesystem = create_filesystem if self[:fstype]
        @volume_group = create_volume_group if self[:volume_group]
    end

    private

    def create_filesystem
        return unless self[:ensure]
        Puppet::Type.type(:filesystem).new(:name => filesystem_name, :fstype => self[:fstype], :size => self[:size], :ensure => self[:ensure])
    end

    def create_volume_group
        return unless self[:ensure]
        args = {:name => self[:volume_group], :ensure => self[:ensure]}
        args.merge!(:physical_volumes => self[:physical_volumes]) if self[:physical_volumes]
        Puppet::Type.type(:volume_group).new(args)
    end

    def filesystem_name
        "/dev/#{self[:volume_group]}/#{self[:name]}"
    end
end
