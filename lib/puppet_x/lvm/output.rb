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
      # Use item_preserve to ensure prefix is not removed from these columns
      def self.parse(key, columns, data, item_preserve = [])
        results = {}

        # Remove prefixes
        columns = columns.map { |col| remove_prefix(col, item_preserve) }
        key     = remove_prefix(key, item_preserve)

        data.split("\n").each do |line|
          parsed_line = line.gsub(%r{\s+}, ' ').strip.split
          values      = columns.zip(parsed_line).to_h
          current_key = values[key]
          values.delete(key)
          results[current_key] = values.compact
        end

        results
      end

      def self.remove_prefix(item, preserve = [])
        return item if preserve.include?(item)

        item.gsub(%r{^[A-Za-z]+_}, '')
      end
    end
  end
end
