require 'pathname'

Puppet::Type.newtype(:filesystem) do
    desc "The filesystem type"

    ensurable do
        newvalue(/^\w+$/, :event => :created_filesystem) do |fstype|
            provider.create(fstype)
        end

        def insync?(desired_fstype)
            provider.fstype == desired_fstype
        end
    end

    newparam(:name) do
        validate do |value|
            unless Pathname.new(value).absolute?
                raise ArgumentError, "Filesystem names must be fully qualified"
            end
        end
    end

    autorequire :logical_volume do
        [[:logical_volume, File.basename(self[:name])]]
    end
end
