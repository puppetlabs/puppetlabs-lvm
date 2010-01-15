require "rexml/document"
require "singleton"

module Puppet
    module Conga
        class ModstorageWrapper
            include Singleton

            RICCI_MODSTORAGE="/usr/libexec/ricci-modstorage"
            #        RICCI_MODSTORAGE="/home/sseago/devel/conga/ricci/modules/storage/ricci-modstorage"
            MODSTORAGE_API_VERSION="1.0"
            MODSTORAGE_SEQUENCE="1254"
            MODSTORAGE_CACHE_EXPIRATION = 60*5

            private_class_method :new
            def initialize
                @count = 0
                @updatecount = 0
                @mapper_ids = nil
                @mappers = nil
                @mapper_templates = nil
                @time = nil
            end

            # Updates the mapper XML docs by using the modstorage "report"
            # API to return full system mapper information in a single
            # modstorage call 

            # calls get_mapper_ids on modstorage)
            #
            def update_mappers
                @updatecount += 1
                outputdoc = send_request("report", [], false)
                @time = Time.now
                @mapper_ids = outputdoc.elements["response/function_response/var[@name='mapper_ids']"]
                @mappers = outputdoc.elements["response/function_response/var[@name='mappers']"]
                @mapper_templates = outputdoc.elements["response/function_response/var[@name='mapper_templates']"]
            end  
            private :update_mappers

            def mapper_ids
                unless (uptodate?)
                    update_mappers
                end
                @mapper_ids
            end
            def mappers
                unless (uptodate?)
                    update_mappers
                end
                @mappers
            end
            def mapper_templates
                unless (uptodate?)
                    update_mappers
                end
                @mapper_templates
            end
            def uptodate?
                @mapper_templates && @time && (Time.now < @time + MODSTORAGE_CACHE_EXPIRATION)
            end
            private :uptodate?

            #
            # Generates the request XML element for passing a basic command to modstorage
            #
            def get_request_element
                req_element = REXML::Element.new("request")
                req_element.add_attribute("API_version", MODSTORAGE_API_VERSION)
                req_element.add_attribute("sequence", MODSTORAGE_SEQUENCE)
                return req_element
            end
            private :get_request_element

            #
            # Generates the request XML element for passing a basic command to modstorage
            #
            def get_function_call_element(function_call_name)
                function_call = REXML::Element.new("function_call")
                function_call.add_attribute("name", function_call_name)
                return function_call
            end
            private :get_function_call_element

            #
            # Runs ricci-modstorage, passing in the xml document referenced by request
            #
            # Returns the xml response
            #
            def send_request(command, var_array, invalidate_mappers)
                unless (File.exist?(RICCI_MODSTORAGE))
                    raise Puppet::Error, "modstorage is not installed or supported, file not found: #{RICCI_MODSTORAGE}"
                end
                @count += 1
                #            debug "#{@count} modstorage runs"

                doc = REXML::Document.new 
                doc << REXML::XMLDecl.new
                request = get_request_element
                function_call_element = get_function_call_element(command)
                unless var_array.is_a?(Array)
                    var_array = [var_array]
                end
                var_array.each {|var_element| function_call_element.add_element(var_element.element)}
                request.add_element(function_call_element)
                doc.add_element(request)
                modstorage = IO.popen(RICCI_MODSTORAGE, "w+")
                #print "input #{request}\n" if invalidate_mappers
                modstorage.puts(doc)
                modstorage.close_write
                outputdoc = REXML::Document.new modstorage.gets(nil)
                success_or_err(outputdoc)
                @time = nil if invalidate_mappers
                #print "output: #{outputdoc}\n" if invalidate_mappers
                return outputdoc
            end

            def success_or_err(response)
                if (api_error = response.elements["/API_error"])
                    raise Puppet::Error, "Storage module API error: #{api_error}"
                end
                success = response.elements["/response/function_response/var[@name='success']"]
                unless (success && success.attributes["value"].eql?("true"))
                    raise Puppet::Error, "failed puppet command #{response}"
                end
            end
            
            def create_bd(bd)
                send_request("create_bd", XmlVarElement.new("bd", "xml", bd), true)
            end
            def modify_bd(bd)
                send_request("modify_bd", XmlVarElement.new("bd", "xml", bd), true)
            end
            def remove_bd(bd)
                send_request("remove_bd", XmlVarElement.new("bd", "xml", bd), true)
            end
            def create_mapper(mapper)
                send_request("create_mapper", XmlVarElement.new("mapper", "xml", mapper), true)
            end
            def modify_mapper(mapper)
                send_request("modify_mapper", XmlVarElement.new("mapper", "xml", mapper), true)
            end
            def remove_mapper(mapper)
                send_request("remove_mapper", XmlVarElement.new("mapper", "xml", mapper), true)
            end
            def add_block_devices(mapper, bd_names)
                new_block_devices = REXML::XPath.match(mapper,"new_sources/block_device")
                old_block_devices = REXML::XPath.match(mapper,"sources/block_device")
                bd_list = []
                bd_names.each do |path|
                    unless (old_block_devices.detect {|device| device.attributes["path"].eql?(path)})
                        unless (bd = (new_block_devices.detect {|device| device.attributes["path"].eql?(path)}))
                            raise Puppet::Error, "Partition #{path} not available"
                        end
                        #          debug "bd: #{path}"
                        bd_list << bd
                    end
                end
                #      debug "add command: #{doc}
                add_mapper_sources(mapper, bd_list) unless bd_list.empty?
            end
            def add_mapper_sources(mapper, bd_list)
                response = send_request("add_mapper_sources", 
                                        [VarElement.new("mapper_type", "string", mapper.attributes["mapper_type"] ),
                                         VarElement.new("mapper_id",   "string", mapper.attributes["mapper_id"]),
                                         VarElement.new("mapper_state_ind", "string", mapper.attributes["state_ind"]),
                                         XmlVarElement.new("bds", "list_xml", bd_list)], true)
                #      debug "response: #{response}"
            end

            class AbstractVarElement
                attr_reader :element
                def initialize(name, type)
                    @element = REXML::Element.new("var")
                    @element.add_attribute("name", name)
                    @element.add_attribute("type", type)
                end
            end
            
            class VarElement < AbstractVarElement
                def initialize(name, type, value)
                    super(name, type)
                    self.element.add_attribute("value", value)
                end
            end
            
            class XmlVarElement < AbstractVarElement
                def initialize(name, type, content)
                    super(name, type)
                    unless content.is_a?(Array)
                        content = [content]
                    end
                    content.each {|child| self.element.add_element(child)}
                end
            end

        end

    end
end
