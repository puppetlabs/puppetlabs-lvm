module Puppet
    class StorageType < Puppet::Type
        
        def self.preinit
            ensurable do
                newvalue(:present) do
                    debug "setting :present"
                    provider.create
                    debug "setting :present done "
                end
                newvalue(:absent) do
                    debug "setting :absent"
                    provider.remove
                end
            end       
        end

        def flush
            return if self.should(:ensure) == :absent
            provider.flush
        end

        def exists?
            provider.exists?
        end


    end
end
