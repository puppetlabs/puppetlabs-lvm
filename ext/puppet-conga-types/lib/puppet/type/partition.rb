# Partition type
require "puppet/type/storagetype"

module Puppet

    newtype(:partition, Puppet::StorageType) do
        @doc = "The client-side description of a disk partition."

        newparam(:path) do
            desc "The device pathname for the partition."
            isnamevar

            validate do |value|
                debug "validating #{value}"
                unless value =~ /^#{File::SEPARATOR}dev#{File::SEPARATOR}/
                    raise Puppet::Error, "Partition paths must be fully qualified"
                end
            end
        end
    end
end
