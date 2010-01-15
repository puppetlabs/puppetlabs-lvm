Puppet::Type.newtype(:volume_group) do
    @depthfirst = true

    newparam(:name) do
        desc "The name of the volume group."
    end

    newparam(:physical_volumes) do
        desc "The list of physical volumes to be included in the volume group.  Will automatically
            configure any volumes that are unmanaged.  This will also remove physical volumes if the
            volume group is being removed."

        munge do |pvs|
            pvs = Array(pvs)
        end
    end

    ensurable

    autorequire :physical_volume do
        self[:physical_volumes].collect do |pv|
            [:physical_volume, pv]
        end
    end

    def generate
        @physical_volumes
    end

    def initialize(*args)
        super
        @physical_volumes = create_physical_volumes if self[:physical_volumes]
    end

    private

    def create_physical_volumes
        return unless self[:ensure]

        self[:physical_volumes].collect do |name|
            Puppet::Type.type(:physical_volume).new(:name => name, :ensure => self[:ensure])
        end
    end
end
