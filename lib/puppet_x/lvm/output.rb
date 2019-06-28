module Puppet_X
  module LVM
    # Work with LVM Output
    class Output
      # Parses the results of LVMs commands. This does not handle when columns
      # have no data and therefore these columns should be avoided. It returns
      # the data with the prefix removed i.e. "lv_free" would be come "free"
      # this however doesn't descriminate and will turn something like
      # "foo_bar" into "bar"

      def self.parse(key,data)
        results = {}

        data.each do |entry|
          name = entry[key]
          results[name] = {}
          data = data.delete(key)
          entry.each do |k,v|
            k = remove_prefix(k)
            results[name][k] = v
          end
        end

        results
      end

      def self.remove_prefixes(array)
        array.map do |item|
          remove_prefix(item)
        end
      end

      def self.remove_prefix(item)
        item.gsub(%r{^[A-Za-z]+_}, '')
      end
    end
  end
end
