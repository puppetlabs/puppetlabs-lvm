require 'puppet/conga'

Puppet::Type.type(:logicalvolume).provide :conga, :parent => Puppet::Conga::StorageElement do
    desc "Logical Volume management based on Conga's ricci_modstorage"

    def initialize(arg)
        super(arg)
        elementname = @model[:path]
        desc = "Logical Volume #{elementname}"
        @path = elementname
        refresh
    end

    def block_device
        self.managed_element
    end

    def refresh
        self.managed_element = Puppet::Conga::ModstorageWrapper.instance.mappers.elements["mapper[@mapper_type='volume_group']/targets/block_device[@path='#{@path}']"]
    end

    def localcreate
        bd_template = Puppet::Conga::StorageElement.new("block device template for logical volume #{@model.get_lvname}")
        REXML::XPath.each(Puppet::Conga::ModstorageWrapper.instance.mappers, 
                          "mapper[@mapper_id='volume_group:#{@model.get_vgname}']/new_targets/block_device_template[@mapper_type='volume_group']") do |template|
            if (template.elements["properties/var[@name='snapshot' and @value='false']"])
                bd_template.managed_element = template
                break
            end
        end
        unless bd_template.exists?
            raise Puppet::Error, "block device template is not available"
        end
        #    debug "template before: #{bd_template}"
        bd_template["lvname"] = @model.get_lvname
        bd_template["size"] = bd_template.get_size(@model.should(:size))
        
        #    debug "template after: #{bd_template}"
        Puppet::Conga::ModstorageWrapper.instance.create_bd(bd_template.managed_element)
    end

    def localremove
        if (self["removable"] == "false")
            raise Puppet::Error, "Logical Volume #{@path} is not removable"
        end
        response = Puppet::Conga::ModstorageWrapper.instance.remove_bd(block_device)
        #    debug "response: #{response}"
    end

    def localflush
        self["size"] = get_size(@model.should(:size))
        Puppet::Conga::ModstorageWrapper.instance.modify_bd(self.block_device)
    end

    def size
        if (exists?)
            @is = self["size"].to_i
        else
            @is = :absent
        end
    end

    def size_insync?
        get_size(@model.should(:size)) == size
    end
end
