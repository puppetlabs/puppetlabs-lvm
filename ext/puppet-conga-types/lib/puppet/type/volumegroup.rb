require "puppet/type/storagetype"

module Puppet

    newtype(:volumegroup, Puppet::StorageType) do
        @doc = "The client-side description of an LVM volume group."

        newparam(:name) do
            desc "The name of the volume group."
            isnamevar

            validate do |value|
                #unless value =~ /^#{File::SEPARATOR}dev#{File::SEPARATOR}/
                #    raise Puppet::Error, "Partition paths must be fully qualified"
                #end
            end
        end

        newstate(:physicalvolumes) do
            desc ""
            newvalue(%r{/dev/.*}) do 
                print "local fs partition"
            end
            def should
                return @should
            end
            def retrieve
                @is = provider.physicalvolumes
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
                # do nothing here
                return :volumegroup_changed
            end
        end

        autorequire(:partition) do
            part = []
            if (self.should(:ensure)==:present) 
                debug "volumegroup #{self[:name]} is present"
                unless ((physicalvolumes = self.should(:physicalvolumes)).nil?)
                    part = physicalvolumes.collect do |path|
                        if ((type = Puppet::Type.type("partition")[path]).is_a?(Puppet::Type))
                            debug "pv: device, partition: #{type}"
                        elsif ((type = Puppet::Type.type("mdraid")[path]).is_a?(Puppet::Type))
                            debug "device, mdraid: #{type}"
                        else
                            raise Puppet::Error, "Cannot find block device #{path} for volumegroup #{self[:name]}"
                        end
                        unless (type.should(:ensure)==:present)
                            raise Puppet::Error, "Block device #{path} for volumegroup #{self[:name]} must be present"
                        end
                        type
                    end
                end
            elsif (self.should(:ensure)==:absent) 
                debug "volumegroup #{self[:name]} is absent"
                Puppet::Type.type("logicalvolume").each do |logicalvolume| 
                    if (logicalvolume.get_vgname == self[:name])
                        unless (logicalvolume.should(:ensure) == :absent) 
                            raise Puppet::Error, "Deleting  volumegroup #{self[:name]}: logical volume #{logicalvolume[:path]} must be absent"
                        end
                        part << logicalvolume
                    end
                end
            end
            debug "requiring: #{part}"
            part
        end
    end
end
