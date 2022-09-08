require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4615 - C96570 - create filesystem with parameter 'use_fs_label'"

# initilize
pv = '/dev/sdc'
vg = ('VolumeGroup_' + SecureRandom.hex(2))
lv = ('fslabel' + SecureRandom.hex(3))

# Teardown
teardown do
  confine_block(:except, roles: ['master', 'dashboard', 'database']) do
    agents.each do |agent|
      remove_all(agent, pv, vg, lv)
    end
  end
end

pp = <<-MANIFEST
physical_volume {'#{pv}':
  ensure  => present,
}
->
volume_group {'#{vg}':
  ensure            => present,
  physical_volumes  => '#{pv}',
}
->
logical_volume{'#{lv}':
  ensure        => present,
  volume_group  => '#{vg}',
  size          => '20M',
  use_fs_label  => true,
  createfs      => true,
  fs_type       => 'ext4',
  options       => '-b 4096 -E stride=32,stripe-width=64',
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, manifest: pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create logical volumes'
confine_block(:except, roles: ['master', 'dashboard', 'database']) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), acceptable_exit_codes: [0, 2]) do |result|
      assert_no_match(%r{Error:}, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the logical volume has correct format type: #{lv}"
    is_correct_format?(agent, vg, lv, 'ext4')
  end
end
