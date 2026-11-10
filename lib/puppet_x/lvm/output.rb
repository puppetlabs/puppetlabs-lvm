# frozen_string_literal: true

module Puppet_X
  module LVM
    # Work with LVM Output
    class Output
      SEPARATOR = ','
      ARGS = [
        '--noheadings',
        '--separator', SEPARATOR,
        '--nosuffix'
      ].freeze

      # Parses the results of LVMs commands. It returns
      # the data with the prefix removed i.e. "lv_free" would be come "free"
      # this however doesn't descriminate and will turn something like
      # "foo_bar" into "bar"
      # Use item_preserve to ensure prefix is not removed from these columns
      def self.parse(key, columns, data, item_preserve = [])
        # Remove prefixes
        columns = columns.map { |col| remove_prefix(col, item_preserve) }
        key     = remove_prefix(key, item_preserve)
        key_idx = columns.index(key)

        data.lines.each_with_object({}) do |line, results|
          parsed_line = line.lstrip.chomp.split(self::SEPARATOR)
          results[parsed_line[key_idx]] = columns.each_with_index.each_with_object({}) do |(col, idx), line_hash|
            next if idx == key_idx

            line_hash[col] = parsed_line[idx]
          end
        end
      end

      def self.remove_prefix(item, preserve = [])
        return item if preserve.include?(item)

        item.gsub(%r{^[A-Za-z]+_}, '')
      end
    end
  end
end
