# Verify if a physical volume, volume group, logical volume, or filesystem resource type is created
#
# ==== Attributes
#
# * +resource_type+ - resorce type, i.e 'physical_volume', 'volume_group', 'logical_volume', or 'filesystem'
# * +resource_name+ - The name of resource type, i.e '/dev/sdb' for physical volume, vg_1234 for volume group
#
# ==== Returns
#
# +nil+
#
# ==== Raises
# assert_match failure message
# ==== Examples
#
# verify_if_created?(agent, 'physical_volume', /dev/sdb')
def verify_if_created?(agent, resource_type, resource_name)
  case resource_type
    when 'physical_volume'
      on(agent, "pvdisplay") do |result|
        assert_match(/#{resource_name}/, result.stdout, 'Unexpected error was detected')
      end
    when 'volume_group'
      on(agent, "vgdisplay") do |result|
        assert_match(/#{resource_name}/, result.stdout, 'Unexpected error was detected')
      end
    when 'logical_volume'
      on(agent, "lvdisplay") do |result|
        assert_match(/#{resource_name}/, result.stdout, 'Unexpected error was detected')
      end
  end
end
