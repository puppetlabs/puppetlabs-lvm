Puppet::Type.newtype(:physical_volume) do
    newparam(:name) do
        validate do |value|
            unless value =~ /^#{File::SEPARATOR}/
                raise ArgumentError, "Physical Volume names must be fully qualified"
            end
        end
    end

    ensurable
end
