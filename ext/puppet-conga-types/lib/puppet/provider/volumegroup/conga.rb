require 'puppet/conga'

Puppet::Type.type(:volumegroup).provide :conga, :parent => Puppet::Conga::StorageElement do
    desc "Volume Group management based on Conga's ricci_modstorage"

    def initialize(arg)
        super(arg)
        elementname = @model[:name]
        desc = "Volume Group #{elementname}"
        @vgname = elementname
        refresh
    end

    def refresh
        self.managed_element = Puppet::Conga::ModstorageWrapper.instance.mappers.elements["mapper[@mapper_id='volume_group:#{@vgname}']"]
    end

    def mapper
        self.managed_element
    end

    def localcreate
        template = Puppet::Conga::StorageElement.new("Volume Group mapper template for #{@vgname}")
        template_element = Puppet::Conga::ModstorageWrapper.instance.mapper_templates.elements["mapper_template[@mapper_type='volume_group']"]
        template.managed_element = template_element
        unless (template.exists?)
            raise Puppet::Error, "no partitions available for new template"
        end
        #debug "template before: #{template}"
        template["vgname"] = name
        @model.should(:physicalvolumes).each do |partition|
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
    end

    def localremove
        remove_physicalvolumes(physicalvolumes)
    end

    def localflush
        add_physicalvolumes(@model.should(:physicalvolumes) - @model.is(:physicalvolumes))
        remove_physicalvolumes(@model.is(:physicalvolumes) - @model.should(:physicalvolumes))
    end

    #
    # removes the specified partitions from the volume group
    #
    def remove_physicalvolumes(partition_list)
        partition_list.each do |partition_path|
            unless (partition_device = (Puppet::Conga::ModstorageWrapper.instance.mappers.elements["mapper[@mapper_id='volume_group:#{@vgname}']/sources/block_device[@path='#{partition_path}']"]))
                raise Puppet::Error, "Partition #{partition_path} not found in volume group #{@vgname}"
            end
            Puppet::Conga::StorageElement.move_new_content(partition_device,"content_template[@type='none']")
            Puppet::Conga::ModstorageWrapper.instance.modify_bd(partition_device)          
        end
    end
    
    #
    # adds the specified partitions to the volume group
    #
    def add_physicalvolumes(partition_list)
        Puppet::Conga::ModstorageWrapper.instance.add_block_devices(mapper, partition_list)
    end

    #
    # Returns an list if partition names which make up a given volume group
    #
    def physicalvolumes
        if (exists?)
            REXML::XPath.match(mapper, "sources/block_device").collect do |element|
                element.attributes["path"]
            end    
        else
            []
        end
    end

end
