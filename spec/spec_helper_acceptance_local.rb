require 'pry'
require 'singleton'
require 'serverspec'
require 'puppetlabs_spec_helper/module_spec_helper'
include PuppetLitmus
# Verify if a physical volume, volume group, logical volume, or filesystem resource type is created
#
# ==== Attributes
#
# * +resource_type+ - resorce type, i.e 'physical_volume', 'volume_group', 'logical_volume', 'filesystem',
# *                   'aix_physical_volume', 'aix_volume_group', or 'aix_logical_volume'.
# * +resource_name+ - The name of resource type, i.e '/dev/sdb' for physical volume, vg_1234 for volume group
# * +vg+ - volume group name associated with logical volume (if any)
# * +properties+ - a matching string or regular expression in logical volume properties
# ==== Returns
#
# +nil+
#
# ==== Raises
# assert_match failure message
# ==== Examples
#
# verify_if_created?(agent, 'physical_volume', /dev/sdb', VolumeGroup_123, "Size     7GB")
def verify_if_created?(resource_type, resource_name, vg = nil, properties = nil)
  case resource_type
  when 'physical_volume'
    run_shell('pvdisplay') do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
    end
  when 'volume_group'
    run_shell('vgdisplay') do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
    end
  when 'logical_volume'
    raise ArgumentError, 'Missing volume group that the logical volume is associated with' unless vg
    run_shell("lvdisplay /dev/#{vg}/#{resource_name}") do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
      if properties
        assert_match(%r{#{properties}}, result.stdout, 'Unexpected error was detected')
      end
    end
  when 'aix_physical_volume'
    run_shell("lspv #{resource_name}") do |result|
      assert_match(%r{Physical volume #{resource_name} is not assigned to}, result.stdout, 'Unexpected error was detected')
    end
  when 'aix_volume_group'
    run_shell('lsvg') do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
    end
  when 'aix_logical_volume'
    raise ArgumentError, 'Missing volume group that the logical volume is associated with' unless vg
    run_shell("lslv #{resource_name}") do |result|
      assert_match(%r{#{resource_name}}, result.stdout, 'Unexpected error was detected')
      if properties
        assert_match(%r{#{properties}}, result.stdout, 'Unexpected error was detected')
      end
    end
  end
end

# Clean the box after each test, make sure the newly created logical volumes, volume groups,
# and physical volumes are removed at the end of each test to make the server ready for the
# next test case.
#
# ==== Attributes
#
# * +pv+ - physical volume, can be one volume or an array of multiple volumes
# * +vg+ - volume group, can be one group or an array of multiple volume groups
# * +lv+ - logical volume, can be one volume or an array of multiple volumes
# * +aix+ - if the agent is an AIX server.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
# +nil+
# ==== Examples
#
# remove_all('/dev/sdb', 'VolumeGroup_1234', 'LogicalVolume_fa13')
def remove_all(pv = nil, vg = nil, lv = nil, aix = false)
  if aix
    run_shell("reducevg -d -f #{vg} #{pv}")
    run_shell("rm -rf /dev/#{vg} /dev/#{lv}")
  else
    if lv
      if lv.is_a?(Array)
        lv.each do |logical_volume|
          run_shell("umount /dev/#{vg}/#{logical_volume}", expect_failures: true)
          run_shell("lvremove /dev/#{vg}/#{logical_volume} --force", expect_failures: true)
        end
      else
        # NOTE: in some test cases, for example, the test case 'create_vg_property_logical_volume'
        # the logical volume must be unmount before being able to delete it
        run_shell("umount /dev/#{vg}/#{lv}", expect_failures: true)
        run_shell("lvremove /dev/#{vg}/#{lv} --force", expect_failures: true)
      end
    end

    if vg
      if vg.is_a?(Array)
        vg.each do |volume_group|
          run_shell("vgremove /dev/#{volume_group}")
        end
      else
        run_shell("vgremove /dev/#{vg}")
      end
    end

    if pv
      if pv.is_a?(Array)
        pv.each do |physical_volume|
          run_shell("pvremove #{physical_volume}")
        end
      else
        run_shell("pvremove #{pv}")
      end
    end
  end
end

RSpec.configure do |c|
  c.before :suite do
    auth_tok = 'pvxejsxwstwhsy0u2tjolfovg9wfzg2e'
    fail_test 'AUTH_TOKEN must be set' unless auth_tok
    machine = ENV['TARGET_HOST']
    command = "curl -H X-AUTH-TOKEN:#{auth_tok} -X POST --url vcloud.delivery.puppetlabs.net/api/v1/vm/#{machine}/disk/1"
    fdisk = run_shell('fdisk -l').stdout
    unless %r{sdb}.match?(fdisk)
      stdout, _stderr, _status = Open3.capture3(command)
      sleep(30)
      run_shell('echo "- - -" >/sys/class/scsi_host/host2/scan')
    end
    unless %r{sdc}.match?(fdisk)
      stdout, _stderr, _status = Open3.capture3(command)
      sleep(30)
      run_shell('echo "- - -" >/sys/class/scsi_host/host2/scan')
    end
    pp = <<-MANIFEST
      package { 'lvm2':
        ensure => 'latest',
      }  
      package { 'util-linux':
        ensure => 'latest',
      }
    MANIFEST
    LitmusHelper.instance.apply_manifest(pp)
  end
end
