require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4579 - C96593 - create physical volume  without parameter 'unless_vg'"

#initilize
pv1 = '/dev/sdc'
pv2 = '/dev/sdd'
vg = ("VG_" + SecureRandom.hex(3))

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    on(agent, "vgremove #{vg}")
    on(agent, "pvremove #{pv1} #{pv2}")
  end
end

pp = <<-MANIFEST
physical_volume {'#{pv1}':
  ensure => present,
}
->
volume_group {'#{vg}':
  ensure            => present,
  physical_volumes  => '#{pv1}',
}
->
physical_volume {'#{pv2}':
  ensure    => present,
  unless_vg => '#{vg}'
}
MANIFEST

pp2 = <<-MANIFEST
physical_volume {'#{pv2}':
  ensure    => present,
  unless_vg => 'non-existing-volume-group'
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)


confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    #Run Puppet Agent with manifest pp
    step "Run Puppet Agent to create volume group '#{vg}' on physical volume '#{pv1}'"
    on(agent, puppet('agent -t --graph  --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the volume group is created: #{vg}"
    verify_if_created?(agent, 'volume_group', vg)

    step "Verify physical volume '#{pv2}' is NOT created since volume group '#{vg}' DOES exist"
    on(agent, "pvdisplay") do |result|
      assert_no_match(/#{pv2}/, result.stdout, 'Unexpected error was detected')
    end
  end
end

#Run Puppet Agent again with manifest pp2
step 'Inject "site.pp" on Master with new manifest'
site_pp = create_site_pp(master, :manifest => pp2)
inject_site_pp(master, get_site_pp_path(master), site_pp)

confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    step "Run Puppet Agent to create the physical volume '#{pv2}':"
    on(agent, puppet('agent -t --graph  --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify physical volume '#{pv2}' is created since volume group 'non-existing-volume-group' DOES NOT exist"
    verify_if_created?(agent, 'physical_volume', pv2)
  end
end


