require 'puppet/conga'

Puppet::Type.type(:mdraid).provide :conga, :parent => Puppet::Conga::StorageElement do
    desc "MDRaid management based on Conga's ricci_modstorage"

    def initialize(arg)
        super(arg)
        elementname = @model.get_device_num
        @device_num = elementname
        desc = "Volume Group #{@devicenum}"
        refresh
    end

    def refresh
        self.managed_element = Puppet::Conga::ModstorageWrapper.instance.mappers.elements["mapper[@mapper_id='mdraid:/dev/md#{@device_num}']"]
    end

    def mapper
        self.managed_element
    end

    def localcreate
        partitions = @model.should(:partitions)
        template = Puppet::Conga::StorageElement.new("MDRaid mapper template for md#{@device_num}")
        template_element = Puppet::Conga::ModstorageWrapper.instance.mapper_templates.elements["mapper_template[@mapper_type='mdraid']"]
        template.managed_element = template_element
        unless (template.exists?)
            raise Puppet::Error, "no partitions available for new template"
        end
        #            debug "template before:  #{template}"
        template["md_device_num"] = @device_num
        template["level"] = @model[:level]
        if (partitions.size < template["min_sources"].to_i)
            raise Puppet::Error, "Too few partitions selected: must be >= #{template["min_sources"]}"
        end
        if (partitions.size > template["max_sources"].to_i)
            raise Puppet::Error, "Too many partitions selected: must be <= #{template["max_sources"]}"
        end
        partitions.each do |partition|
            sources = template_element.elements["sources"]
            new_sources = template_element.elements["new_sources"]
            partition_element = new_sources.elements["block_device[@path='#{partition}']"]
            #      debug "partition_element: #{partition_element}"
            unless partition_element 
                raise Puppet::Error, "partition #{partition} is not available"
            end
            sources.add_element(partition_element)
            new_sources.delete_element(partition_element)
        end
        #            debug "template after: #{template}"
        Puppet::Conga::ModstorageWrapper.instance.create_mapper(template.managed_element)
        if (@model.should(:active)==:false) 
            Puppet::Conga::MDRaid.new(@device_num).set_active(false)
        end
    end

    def localremove
        if (self["removable"] == "false" && self["active"] == "false")
            set_active(:true)
            update_mapper
        end
        if (self["removable"] == "false")
            raise Puppet::Error, "MD Raid array /dev/md#{@device_num} is not removable"
        end
        response = Puppet::Conga::ModstorageWrapper.instance.remove_mapper(mapper)
        #    debug "response: #{response}"
    end

    def localflush
        Puppet::Conga::ModstorageWrapper.instance.add_block_devices(mapper, @model.should(:partitions) - @model.is(:partitions))
        remove_partitions(@model.is(:partitions) - @model.should(:partitions))
        set_active(@model.should(:active))
    end

    def remove_partitions(partition_list)
        partition_list.each do |partition_path|
            unless (partition_device = (mapper.elements["sources/block_device[@path='#{partition_path}']"]))
                raise Puppet::Error, "Partition #{partition_path} not found in mdraid md#{@device_num}"
            end
            source = Puppet::Conga::StorageElement.new("MDRaid source partition for md#{@device_num}")
            source.managed_element = partition_device.elements["content"]
            if (source["failed"] == "false") 
                source["failed"] = "true"
                Puppet::Conga::ModstorageWrapper.instance.modify_bd(partition_device)          
                self.update_mapper
                
                unless (partition_device = (mapper.elements["sources/block_device[@path='#{partition_path}']"]))
                    raise Puppet::Error, "Partition #{partition_path} not found in mdraid md#{@device_num}"
                end
                source.managed_element = partition_device.elements["content"]
            end
            Puppet::Conga::StorageElement.move_new_content(partition_device,"content_template[@type='none']")
            Puppet::Conga::ModstorageWrapper.instance.modify_bd(partition_device)          
        end
    end
    
    def partitions
        if (exists?)
            REXML::XPath.match(mapper, "sources/block_device").collect do |element|
                element.attributes["path"]
            end    
        else
            []
        end
    end

    def active
        if (exists?)
            boolean_to_symbol(self["active"])
        else
            :absent
        end
    end

    def set_active(active)
        self["active"] = boolean_to_string(active)
        Puppet::Conga::ModstorageWrapper.instance.modify_mapper(mapper)
    end
end
