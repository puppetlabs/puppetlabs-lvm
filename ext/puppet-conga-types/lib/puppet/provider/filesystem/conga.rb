require 'puppet/conga'

Puppet::Type.type(:filesystem).provide :conga, :parent => Puppet::Conga::StorageElement do
    desc "Filesystem management based on Conga's ricci_modstorage"

    def initialize(arg)
        super(arg)
        elementname = @model[:device]
        desc = "Extended FS #{elementname}"
        @path = elementname
        refresh
    end
    
    def refresh
        @bd = Puppet::Conga::ModstorageWrapper.instance.mappers.elements["mapper/targets/block_device[@path='#{@path}' and content/@fs_type='ext']"]
        if !(@bd.nil?)
            self.managed_element = @bd.elements["content[@type='filesystem' and @fs_type='ext']"]
        else
            self.managed_element = nil
        end
    end
    def block_device
        unless exists?
            raise Puppet::Error, "Extended FS #{@path} not found."
        end
        @bd
    end
    
    def localcreate
        new_mountpoint = @model.should(:mountpoint)
        if !(new_mountpoint == :absent || (new_mountpoint.is_a?(String) && new_mountpoint.empty?)) 
            mount = :true  
        else 
            mount = :false 
        end
        fs_type = @model[:fs_type]
        if (fs_type == :ext2 || fs_type == :ext3 )
            unless (bd = Puppet::Conga::ModstorageWrapper.instance.mappers.elements["mapper/targets/block_device[@path='#{@path}'][content/available_contents/content_template/@fs_type='ext']"])
                raise Puppet::Error, "block device #{@path} does not exist." #\n#{Puppet::Conga::ModstorageWrapper.instance.mappers}\n"
            end
            content_properties = Puppet::Conga::StorageElement.new("Content properties template for #{@path}")
            content_properties.managed_element = Puppet::Conga::StorageElement.move_new_content(bd,"content_template[@type='filesystem' and @fs_type='ext']")
            content_properties["block_size"] = @model[:block_size]
            content_properties["label"] = @model[:label]
            content_properties["has_journal"] = (fs_type == :ext3 ? "true" : "false")
            content_properties["dir_index"] = content_properties.boolean_to_string(@model.should(:dir_index))
            
            content_properties["fstab"] = content_properties.boolean_to_string(@model[:fstab])
            content_properties["mount"] = content_properties.boolean_to_string(mount)
            if (new_mountpoint == :absent)
                content_properties["mountpoint"] = ""
            else
                content_properties["mountpoint"] = new_mountpoint
            end
            Puppet::Conga::ModstorageWrapper.instance.modify_bd(bd)
            refresh
        else
            raise Puppet::Error, "unsupported FS type #{fs_type}"
        end  
    end

    def localremove
        fs_type = @model[:fs_type]
        if (fs_type == :ext2 || fs_type == :ext3 )
            bd = block_device
            content_properties = Puppet::Conga::StorageElement.new("Content properties template for #{@path}")
            content_properties.managed_element = Puppet::Conga::StorageElement.move_new_content(bd,"content_template[@type='none']")
            Puppet::Conga::ModstorageWrapper.instance.modify_bd(bd)
        else
            raise Puppet::Error, "unsupported FS type #{fs_type}."
        end  
    end

    def localflush
        self["dir_index"] = boolean_to_string(@model.should(:dir_index))
        new_mountpoint = @model.should(:mountpoint)
        if (new_mountpoint == :absent)
            self["mountpoint"] = ""
            self["fstabpoint"] = ""
        else
            self["mountpoint"] = new_mountpoint
            self["fstabpoint"] = (@model[:fstab]==:true) ? new_mountpoint : ""
        end
        Puppet::Conga::ModstorageWrapper.instance.modify_bd(block_device)
    end

    def dir_index
        exists? ? boolean_to_symbol(self["dir_index"]) : :absent
    end

    def mountpoint
        exists? ? self["mountpoint"] : :absent
    end

    #
    # Determines whether a specified size is in sync with the existing block device
    #
    def mount_insync?
        if (exists?)
            new_mountpoint = @model.should(:mountpoint)
            current_mount = self["mountpoint"]
            current_fstab = self["fstabpoint"]
            if (new_mountpoint==:absent)
                (current_mount.empty? && current_fstab.empty?)
            else
                if (@model[:fstab]==:true)
                    (new_mountpoint==current_mount && mountpoint==current_fstab)
                else
                    (new_mountpoint==current_mount && current_fstab.empty?)
                end
            end
        else
            false
        end
    end
end
