# frozen_string_literal: true

module Puppet_X
  module LVM
    # Work with LVM Output
    class Output
      # Parses the results of LVMs commands. This does not handle when columns
      # have no data and therefore these columns should be avoided. It returns
      # the data with the prefix removed i.e. "lv_free" would be come "free"
      # this however doesn't descriminate and will turn something like
      # "foo_bar" into "bar"
      def self.parse(key, columns, data, prefix2remove = '[A-Za-z]+_')
        results = {}

        # Remove prefixes
        columns = remove_prefixes(columns, prefix2remove)
        key     = remove_prefix(key, prefix2remove)

        data.split("\n").each do |line|
          parsed_line = line.gsub(%r{\s+}, ' ').strip.split
          values      = columns.zip(parsed_line).to_h
          current_key = values[key]
          values.delete(key)
          results[current_key] = values
        end

        results
      end

      def self.remove_prefixes(array, prefix)
        array.map do |item|
          remove_prefix(item, prefix)
        end
      end

      def self.remove_prefix(item, prefix)
        item.gsub(%r{^#{prefix}}, '')
      end
    end
  end
end
