require 'puppet/conga'

Puppet::Type.type(:partition).provide :conga do
    desc "Partition management based on Conga's ricci_modstorage"

    confine :exists => Puppet::Conga::ModstorageWrapper::RICCI_MODSTORAGE

    defaultfor :operatingsystem => [:redhat, :fedora]

    def create
        raise Puppet::Error, "Creating partitions is not currently supported"
    end

    def remove
    end

    def flush
    end

    def exists?
        partitions = []
        REXML::XPath.each( Puppet::Conga::ModstorageWrapper.instance.mappers, "mapper[@mapper_type='partition_table']/targets/block_device[@mapper_type='partition_table']") do
            |element| partitions.push(element.attributes["path"])
        end
        partitions.include?(@model[:path])
    end

end
