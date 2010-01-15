require "rexml/document"

module Puppet
    module Conga
        class StorageElement < Puppet::Type::Provider

            attr_reader :desc, :elementname
            attr_writer :desc, :elementname
            def initialize(foo)
                super(foo)
                @managed_element = nil
                @valid = false
                @noflush = false
            end

            def managed_element=(element)
                @managed_element = element
                @valid = !(@managed_element.nil?)
            end

            def managed_element
                unless @valid
                    raise Puppet::Error, "storage element #{@desc} not found."
                end
                @managed_element
            end

            def exists?
                refresh
                @valid
            end

            def flush
                if (!@noflush && exists? && @model.should(:ensure) != :absent)
                    localflush
                end
                @noflush = false
            end

            def refresh
            end

            def localflush
            end

            def create
                localcreate
                @noflush = true
            end

            def localcreate
            end

            def remove
                if (exists?)
                    localremove
                    self.managed_element = nil
                end
            end

            def localremove
            end

            def self.preinit
                confine :exists => ModstorageWrapper::RICCI_MODSTORAGE
                defaultfor :operatingsystem => [:redhat, :fedora]
            end

            def to_s
                "desc: #{@desc.to_s}\nmanaged_element: #{@managed_element.to_s}\nvalid: #{@valid.to_s}\n"
            end

            def [](name)
                unless (var = (self.managed_element.elements["properties/var[@name='#{name}']"]))
                    raise Puppet::Error, "Property #{name} is not available."
                end
                var.attributes["value"]
            end
            
            def []=(name,value)
                return if (value.nil?)
                
                unless (var = (self.managed_element.elements["properties/var[@name='#{name}']"]))
                    raise Puppet::Error, "Property #{name} is not available."
                end
                type = var.attributes["type"]
                #            debug "setting #{name} to #{value} for var #{var}"
                if (type=="string")
                    if (!(min_length = var.attributes["min_length"]).nil? && (value.size < min_length.to_i))
                        raise Puppet::Error, "#{@desc} #{name} #{value} is too short. Min length: #{min_length}"
                    elsif (!(max_length = var.attributes["max_length"]).nil? && (value.size > max_length.to_i))
                        raise Puppet::Error, "#{@desc} #{name} #{value} is too long. Max length: #{max_length}"
                    elsif (!(illegal_chars = var.attributes["illegal_chars"]).nil? && (value.count(illegal_chars) > 0))
                        raise Puppet::Error, "#{@desc} #{name} #{value} contains illegal characters. The following characters are not allowed: #{illegal_chars}"
                    end
                    if (!(reserved_words = var.attributes["reserved_words"]).nil?)
                        reserved_words.split(';').each do |reserved_word|
                            if (value.eql?(reserved_word))
                                raise Puppet::Error, "#{@desc} #{name} #{value} cannot be one of these: #{reserved_words}"
                            end
                        end
                    end
                elsif(type=="int")
                    if (!(min = var.attributes["min"]).nil? && (value.to_i < min.to_i))
                        raise Puppet::Error, "#{@desc} #{name} #{value} is too small. Min: #{min}"
                    elsif (!(max = var.attributes["max"]).nil? && (value.to_i > max.to_i))
                        raise Puppet::Error, "#{@desc} #{name} #{value} is too large. Max: #{max}"
                    end
                elsif(type=="int_select" or type=="string_select")
                    if (!(valid_list = REXML::XPath.match(var, "listentry").join(", ")).empty?)
                        unless (var.elements["listentry[@value='#{value}']"])
                            raise Puppet::Error, "For #{@desc}, #{var.attributes["name"]}: #{value} is invalid. Valid values are #{valid_list}"
                        end
                    end
                end
                #            debug "setting #{name} to #{value}, #{value.class}"
                set_property_var(var, value)
            end
            
            def boolean_to_symbol(val)
                convert_boolean(val, [:true, :false])
            end
            def boolean_to_string(val)
                convert_boolean(val, ["true", "false"])
            end
            def convert_boolean(val,out_array )
                case val
                when "true", true, :true
                    out_array[0]
                when "false", false, :false
                    out_array[1]
                else
                    nil
                end
            end

            def get_size(suggested_size)
                # TODO: this is a hack -- we can't currently check whether the desired value is 
                # "close enough" to the current value when the size in't mutable, so we return the 
                # desired size back. What we need is for the storage module to provide a step value 
                # even when it's not mutable
                unless (size_element = (self.managed_element.elements["properties/var[@name='size']"]))
                    raise Puppet::Error, "Property size is not available."
                end
                if (!(size_element.attributes["mutable"] == "true"))
                    return suggested_size
                end
                min = (size_element.attributes["min"]).to_i
                max = (size_element.attributes["max"]).to_i
                step = (size_element.attributes["step"]).to_i
                if (suggested_size < min)
                    raise Puppet::Error, "Logical Volume size #{suggested_size} is too small. Minimum: #{min}"
                elsif (suggested_size > max)
                    raise Puppet::Error, "Logical Volume size #{suggested_size} is too large. Maximum: #{max}"
                end
                min + ((suggested_size-min)/step)*step
            end

            def set_property_var(element, value)
                unless ((element.attributes["mutable"] == "true"))
                    raise Puppet::Error, "Property #{var.attributes["name"]} is not mutable."
                else
                    element.attributes["value"] = value
                end
            end

            def StorageElement.move_new_content(bd, match)
                available_contents = bd.elements["content/available_contents"]
                new_content = bd.elements["content/new_content"]
                content_to_move = available_contents.elements[match]
                unless content_to_move
                    raise Puppet::Error, "content #{match} is not available in #{available_contents}"
                end
                new_content.add_element(content_to_move)
                available_contents.delete_element(content_to_move)
                content_to_move
            end
            

        end

    end
end
