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
            set this volume group as a dependency, but it must be defined elsewhere using the
            volume_group resource type."
    end

    newparam(:size) do
        desc "The size of the logical volume.  This value will also be used to size the filesystem."
    end
    
    ensurable

    def generate
        [@filesystem].compact
    end

    def initialize(*args)
        super
        @filesystem = create_filesystem if self[:fstype]
    end

    private

    def create_filesystem
        return unless self[:ensure]
        Puppet::Type.type(:filesystem).new(:name => filesystem_name, :fstype => self[:fstype], :size => self[:size], :ensure => self[:ensure])
    end

    def filesystem_name
        "/dev/#{self[:volume_group]}/#{self[:name]}"
    end
end
