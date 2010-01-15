require "puppet/type/storagetype"

# Partition type

module Puppet

    newtype(:filesystem, Puppet::StorageType) do
        @doc = "The client-side description of an LVM logical volume."

        newparam(:device) do
            desc "The label for the filesystem."
            isnamevar

            validate do |value|
                debug "validating #{value}"
                unless value =~ /^#{File::SEPARATOR}dev#{File::SEPARATOR}/
                    raise Puppet::Error, "Partition paths must be fully qualified"
                end
            end
        end

        newparam(:block_size) do
            desc "The block size for the filesystem."

            validate do |value|
                debug "validating #{value}"
                unless value =~ /^[-0-9]+$/
                    raise Puppet::Error, "Block size must be an integer"
                end
            end
        end

        newparam(:label) do
            desc "The label for the filesystem."
        end

        newparam(:fs_type) do
            desc "The filesystem type (ext2, ext3, etc.)"
            newvalues("ext2", "ext3")
        end

        newparam(:fstab) do
            desc "Whether the filesystem is listed in /etc/fstab"
            newvalues(:true, :false)
        end

        autorequire(:logicalvolume) do
            if (self.should(:ensure)==:present) 
                debug "filesystem #{self[:device]} is present"
                path = self[:device]
                if ((type = Puppet::Type.type("logicalvolume")[path]).is_a?(Puppet::Type))
                    debug "device, logicalvolume: #{type}"
                elsif ((type = Puppet::Type.type("partition")[path]).is_a?(Puppet::Type))
                    debug "device, partition: #{type}"
                elsif ((type = Puppet::Type.type("mdraid")[path]).is_a?(Puppet::Type))
                    debug "device, mdraid: #{type}"
                else
                    raise Puppet::Error, "Cannot find block device #{path} for filesystem"
                end
                unless (type.should(:ensure)==:present)
                    raise Puppet::Error, "Block Device #{type} for filesystem   #{self[:device]} must be present"
                end
                type
            else
                debug "filesystem #{self[:device]} is absent, no requires"
                nil
            end
        end

        newstate(:dir_index) do
            desc "Whether the dir_index property is set on the filesystem"
            newvalue(:true) { }
            newvalue(:false) { }
            def retrieve
                @is = provider.dir_index
            end
            def sync
                #doing nothing now
                return :filesystem_changed
            end
        end

        newstate(:mountpoint) do
            desc "Mountpoint for the filesystem"
            newvalue(:absent) { self.should = :absent }
            newvalue(/^#{File::SEPARATOR}/) { }
            def retrieve
                @is = provider.mountpoint
            end
            def insync?
                provider.mount_insync?
            end
            def sync
                #doing nothing now
                return :filesystem_changed
            end
        end
        validate do 
            mountpoint = self.should(:mountpoint)
            fstab = self[:fstab]
            debug "validating mountpoint: #{mountpoint}, fstab: #{fstab}"
            if ((mountpoint == :absent ) and (fstab == :true))
                raise Puppet::Error, "no mountpoint specified: fstab must be false"
           end
        end
    end
end
