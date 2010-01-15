Puppet::Type.newtype(:filesystem) do

    newparam(:name) do
        validate do |value|
            unless value =~ /^#{File::SEPARATOR}/
                raise ArgumentError, "Filesystem names must be fully qualified"
            end
        end
    end

    newparam(:fstype) do
        desc "The filesystem type. Valid values depend on the operating system."
    end

    newparam(:size) do
        desc "The size of the logical volume.  This value will also be used to size the filesystem."
    end

    ensurable

end
