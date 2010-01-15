require "puppet/type/storagetype"

module Puppet

    newtype(:logicalvolume, Puppet::StorageType) do
        @doc = "The client-side description of an LVM logical volume."

        newparam(:path) do
            desc "The device pathname for the logical volume. Must be in the form /dev/$vgname/$lvname"
            isnamevar

            validate do |value|
                debug "validating #{value}"
                sep = File::SEPARATOR
                unless value =~ /^#{sep}dev#{sep}[^#{sep}]+#{sep}[^#{sep}]+$/
                    raise Puppet::Error, "Partition paths must be fully qualified"
                end
            end
        end

        newstate(:size) do
            desc "The logical volume size in bytes."
            munge do |value|
                case value
                when String
                    if value =~ /^[-0-9]+$/
                        value = Integer(value)
                    end
                when Symbol
                    unless value == :absent
                        self.devfail "Invalid Size %s" % value
                    end
                end
                return value
            end

            def retrieve
                provider.size
            end
            # size is insync if @should value is within one step of @is
            def insync?
                unless defined? @should and @should
                    return true
                end

                unless @should.is_a?(Array)
                    self.devfail "%s's should is not array" % self.class.name
                end

                # an empty array is analogous to no should values
                if @should.empty?
                    return true
                end
                provider.size_insync?
            end

            def sync
                # do nothing here
                return :logicalvolume_changed
            end
        end

        def get_vgname 
            self[:path].split('/')[2]
        end

        def get_lvname 
            self[:path].split('/')[3]
        end

        autorequire(:volumegroup) do
            part = []
            if (self.should(:ensure)==:present) 
                debug "logicalvolume #{self[:path]} is present"
                debug "logicalvolume requiring volumegroup: #{get_vgname}"
                if ((type = Puppet::Type.type("volumegroup")[get_vgname]).is_a?(Puppet::Type))
                    unless (type.should(:ensure)==:present)
                        raise Puppet::Error, "Volume Group #{get_vgname} for logical volume  #{self[:path]} must be present"
                    end
                    part << type
                else
                    raise Puppet::Error, "Cannot find volume group #{get_vgname} for logical volume #{self[:path]}"
                end
            elsif (self.should(:ensure)==:absent) 
                debug "logicalvolume #{self[:path]} is absent"
                if ((type = Puppet::Type.type("filesystem")[self[:path]]).is_a?(Puppet::Type))
                    unless (type.should(:ensure) == :absent) 
                        raise Puppet::Error, "Deleting  logicalvolume #{self[:path]}: filesystem #{type[:path]} must be absent"
                    end
                    part << type
                end
            end
            debug "requiring:  #{part}"
            part
        end
    end
end
