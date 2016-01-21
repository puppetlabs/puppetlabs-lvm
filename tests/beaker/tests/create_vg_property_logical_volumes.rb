require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4579 - C97138 - create volume group with property 'logical_volumes'"

#initilize
pv = '/dev/sdd'
vg = ("VG_" + SecureRandom.hex(3))
lv = ("LV_" + SecureRandom.hex(2))

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    on(agent, "umount /dev/#{vg}/#{lv}", :acceptable_exit_codes => [0,1])
    on(agent, "lvremove /dev/#{vg}/#{lv} --force")
    on(agent, "vgremove #{vg}")
    on(agent, "pvremove #{pv}")
  end
end

pp = <<-MANIFEST
class { 'lvm':
  volume_groups    => {
    '#{vg}' => {
      physical_volumes => '#{pv}',
      logical_volumes  => {
        '#{lv}'    => {'size' => '2G'},
      },
    },
  },
}
include ::lvm

MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create volume group'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --graph  --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the volume group is created: #{vg}"
    verify_if_created?(agent, 'volume_group', vg)
  end
end
