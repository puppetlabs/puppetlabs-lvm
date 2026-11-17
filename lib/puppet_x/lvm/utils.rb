# frozen_string_literal: true

module Puppet_X
  module LVM
    # A utility module to handle unified functions.
    class Utils
      # Expand a symlink to the real device path.
      def self.device_expand_path(paths)
        Array(paths).map do |path|
          next path unless File.symlink?(path)

          device = File.expand_path(File.readlink(path), File.dirname(path))
          Puppet.debug("resolved symlink '#{path}' to device '#{device}'")

          device
        end
      end
    end
  end
end
