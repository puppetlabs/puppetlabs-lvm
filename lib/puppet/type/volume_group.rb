Puppet::Type.newtype(:volume_group) do
    @depthfirst = true

    newparam(:name) do
        desc "The name of the volume group."
    end

    newparam(:physical_volumes) do
        desc "The list of physical volumes to be included in the volume group; this
             will automatically set these as dependencies, but they must be defined elsewhere
             using the physical_volume resource type."
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

end
