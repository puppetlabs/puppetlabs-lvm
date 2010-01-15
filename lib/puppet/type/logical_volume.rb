Puppet::Type.newtype(:logical_volume) do
    @depthfirst = true

    newparam(:name) do
        desc "The name of the logical volume."
    end

    newparam(:fstype) do
        desc "The filesystem type. Valid values depend on the operating system."
    end

    newparam(:volume_group) do
        desc "The volume group name associated with this logical volume."
    end

    newparam(:size) do
        desc "The size of the logical volume.  This value will also be used to size the filesystem."
    end
    
    ensurable

    def generate
        @filesystem ? [@filesystem] : nil
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
