require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4579 - C96574 - create logical volume without parameter 'alloc'"

#initilize
pv = '/dev/sdd'
vg = ("VG_" + SecureRandom.hex(2))
lv = [("LV_" + SecureRandom.hex(3)), ("LV_" + SecureRandom.hex(3)), \
("LV_" + SecureRandom.hex(3)), ("LV_" + SecureRandom.hex(3)), ("LV_" + SecureRandom.hex(3))]

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    lv.each do |logical_volume|
      on(agent, "umount /dev/#{vg}/#{logical_volume}", :acceptable_exit_codes => [0,1])
      on(agent, "lvremove /dev/#{vg}/#{logical_volume} --force")
    end
    on(agent, "vgremove #{vg}")
    on(agent, "pvremove #{pv}")
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
logical_volume{'#{lv[0]}':
  ensure        => present,
  volume_group  => '#{vg}',
  alloc         => 'anywhere',
  size          => '20M',
}
->
logical_volume{'#{lv[1]}':
  ensure        => present,
  volume_group  => '#{vg}',
  alloc         => 'contiguous',
  size          => '10M',
}
->
logical_volume{'#{lv[2]}':
  ensure        => present,
  volume_group  => '#{vg}',
  alloc         => 'cling',
  size          => '15M',
}
->
logical_volume{'#{lv[3]}':
  ensure        => present,
  volume_group  => '#{vg}',
  alloc         => 'inherit',
  size          => '30M',
}
->
logical_volume{'#{lv[4]}':
  ensure        => present,
  volume_group  => '#{vg}',
  alloc         => 'normal',
  size          => '5M',
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create logical volumes'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --graph  --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the logical volume  is created: #{lv}"
    verify_if_created?(agent, 'logical_volume', lv)
  end
end
