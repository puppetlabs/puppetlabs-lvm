require 'pathname'

Puppet::Type.newtype(:filesystem) do

    desc "The filesystem type"

    ensurable do
        newvalue(/^\w+$/, :event => :created_filesystem) do
            provider.create
        end
        def retrieve
            provider.fstype
        end
        def insync?(desired_fstype)
            provider.fstype == desired_fstype
        end
    end

    newparam(:name) do
        isnamevar
        validate do |value|
            unless Pathname.new(value).absolute?
                raise ArgumentError, "Filesystem names must be fully qualified"
            end
        end
    end

end
