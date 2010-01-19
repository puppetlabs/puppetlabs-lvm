require 'pathname'

Puppet::Type.newtype(:filesystem) do

    newparam(:name) do
        validate do |value|
            unless Pathname.new(value).absolute?
                raise ArgumentError, "Filesystem names must be fully qualified"
            end
        end
    end

    newparam(:fstype) do
        desc "The filesystem type. Valid values depend on the operating system."
    end

    newparam(:size) do
        desc "The size of the logical volume.  Set to undef to use all available space."
    end

    ensurable

    autorequire :logical_volume do
        [[:logical_volume, File.basename(self[:name])]]
    end

end
