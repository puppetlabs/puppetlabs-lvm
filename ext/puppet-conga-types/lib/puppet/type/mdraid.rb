require "puppet/type/storagetype"

module Puppet

    newtype(:mdraid, Puppet::StorageType) do
        @doc = "The client-side description of an mdraid array."

        newparam(:device) do
            desc "The device pathname for the mdraid array. Must be in the form /dev/md[$raid-num]"
            isnamevar

            validate do |value|
                debug "validating #{value}"
                unless value =~ /^#{File::SEPARATOR}dev#{File::SEPARATOR}md[12]?[0-9]$/
                    raise Puppet::Error, "mdraid paths must be fully qualified"
                end
            end
        end

        newparam(:level) do
            desc "The raid level for this array (raid1, raid5)"
            newvalues("raid1", "raid5")
        end

        newstate(:partitions) do
            desc ""
            newvalue(%r{/dev/.*}) do 
                print "local fs partition"
            end
            def should
                return @should
            end
            def retrieve
                @is = provider.partitions
            end
            # partition list is insync if it contains the same elements
            # nil value results in deleting volgroup
            def insync?
                unless defined? @should and @should
                    return !@parent.exists?
                end

                unless @should.is_a?(Array)
                    self.devfail "%s's should is not array" % self.class.name
                end

                # an empty array is analogous to no should values
                if @should.empty?
                    return true
                end
                return @should.sort.eql?(@is.sort)
            end

            def sync
                #nothing here
                return :volumegroup_changed
            end
        end

        newstate(:active) do
            desc "Whether the raid array is active"
            newvalue(:true) { }
            newvalue(:false) { }
            def retrieve
                @is = provider.active
            end
            def sync
                #do nothing here
                return :mdraid_changed
            end
        end

        autorequire(:partition) do
            part = []
            if (self.should(:ensure)==:present) 
                unless ((partitions = self.should(:partitions)).nil?)
                    part = partitions.collect do |partition|
                        unless ((type = Puppet::Type.type("partition")[partition]).is_a?(Puppet::Type))
                            raise Puppet::Error, "Cannot find block device #{partition} for mdraid #{self[:device]}"
                        end
                        unless (type.should(:ensure)==:present)
                            raise Puppet::Error, "Block device #{partition} for mdraid #{self[:device]} must be present"
                        end
                        type
                    end
                end
            elsif (self.should(:ensure)==:absent) 
                if ((type = Puppet::Type.type("filesystem")[self[:device]]).is_a?(Puppet::Type))
                    unless (type.should(:ensure) == :absent) 
                        raise Puppet::Error, "Deleting  mdraid #{self[:device]}: filesystem #{type[:device]} must be absent"
                    end
                    part << type
                else
                    foundvol = false
                    Puppet::Type.type("volumegroup").each do |volumegroup| 
                        if (!(pvs = volumegroup.should(:physicalvolumes)).nil? and pvs.include?(self[:device]))
                            unless (volumegroup.should(:ensure) == :absent) 
                                raise Puppet::Error, "Deleting  mdraid #{self[:device]}: volumegroup #{volumegroup[:name]} must be absent"
                            end
                            part << volumegroup
                            foundvol = true
                            break
                        end
                    end
                    unless (foundvol)
                        Puppet::Type.type("volumegroup").each do |volumegroup| 
                            if (volumegroup.provider.exists? and volumegroup.provider.partitions.include?(self[:device]))
                                part << volumegroup
                                break
                            end
                        end
                    end
                end
            end
            debug "requiring: #{part}"
            part
        end
        def get_device_num 
            self[:device][/[0-9]+$/]
        end
    end
end
