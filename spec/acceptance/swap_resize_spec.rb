# frozen_string_literal: true

require 'spec_helper_acceptance'

# RHEL10 acceptance test for https://github.com/puppetlabs/puppetlabs-lvm/issues/372
#
# Resizing a swap logical volume runs `swapoff && mkswap && swapon` (swap branch
# of lib/puppet/provider/logical_volume/lvm.rb#size=), and `mkswap` mints a fresh
# random UUID on every run. On RHEL 10 swap is referenced by UUID in /etc/fstab
# and in the `resume=UUID=` kernel parameter, so the regenerated UUID orphans
# those references: swap fails to reactivate at boot and hibernation breaks. On
# RHEL 9 and earlier swap was referenced by device path, so the issue has only
# been reported on RHEL 10 -- hence this test only runs there.
#
# A probe against the provisioned RHEL 10 image (git history: 2026-07) showed it
# is an anaconda install but ships NO swap and NO LVM, so there is no pre-existing
# OS swap to resize. We therefore build the standard swap-by-UUID condition the
# way an admin/anaconda would -- create the swap LV with the module, then persist
# it in fstab by UUID -- and observe the REAL failure through the real swapon/fstab
# path: after a module resize, re-activating swap from fstab (as a reboot does)
# no longer works because the UUID changed. Hibernation/resume= is not exercised
# (no hibernation in CI) but shares the identical root cause.
#
# Expected lifecycle: RED on RHEL 10 with the current provider, GREEN once the
# resize preserves the UUID (e.g. `mkswap -U <existing-uuid>`); skipped elsewhere.
describe 'resize a swap logical volume referenced by UUID' do
  before(:each) do
    skip 'Only applicable to RHEL/EL 10+, where fstab and resume= reference swap by UUID' unless os[:family] == 'redhat' && os[:release].to_s.to_i >= 10
  end

  let(:device_name) do
    (os[:arch] == 'aarch64') ? 'nvme0n3' : 'sdc'
  end

  let(:pv) { "/dev/#{device_name}" }
  let(:vg) { 'VolumeGroup_swap' }
  let(:lv) { 'LogicalVolume_swap' }
  let(:device_path) { "/dev/#{vg}/#{lv}" }
  let(:fstab_marker) { '# puppetlabs-lvm issue-372 swap test' }

  let(:pp_create) do
    <<~MANIFEST
      physical_volume { '#{pv}':
        ensure => present,
      }
      ->
      volume_group { '#{vg}':
        ensure           => present,
        physical_volumes => '#{pv}',
      }
      ->
      logical_volume { '#{lv}':
        ensure       => present,
        volume_group => '#{vg}',
        size         => '100M',
        yes_flag     => true,
      }
      ->
      filesystem { 'Create_swap':
        name    => '#{device_path}',
        ensure  => present,
        fs_type => 'swap',
      }
    MANIFEST
  end

  let(:pp_resize) do
    <<~MANIFEST
      logical_volume { '#{lv}':
        ensure       => present,
        volume_group => '#{vg}',
        size         => '200M',
        yes_flag     => true,
      }
    MANIFEST
  end

  it 'keeps swap reachable via its fstab UUID after a resize' do
    # 1. Create the swap LV with the module (its own documented feature).
    #    yes_flag => true lets lvcreate wipe any stale filesystem signature left
    #    on the shared scratch disk by earlier specs, matching how an admin reuses
    #    a disk that previously held a filesystem.
    apply_manifest(pp_create, catch_failures: true)
    expect(run_shell("blkid -s TYPE -o value #{device_path}").stdout.strip).to eq('swap')

    # 2. Persist it in fstab by UUID -- the standard, anaconda-equivalent way to
    #    record swap on RHEL 10.
    uuid = run_shell("blkid -s UUID -o value #{device_path}").stdout.strip
    expect(uuid).not_to be_empty
    run_shell(%(printf '%s\\nUUID=%s none swap defaults 0 0\\n' '#{fstab_marker}' '#{uuid}' >> /etc/fstab))

    # 3. Baseline: swap activates from its fstab UUID entry before any resize.
    run_shell('swapoff -a')
    run_shell('swapon -a || true')
    baseline_swap = run_shell('swapon --show --noheadings').stdout.strip
    expect(baseline_swap).not_to be_empty, 'precondition failed: swap did not activate from its fstab UUID entry before the resize'

    # 4. Resize the swap LV with the module -- the operation issue #372 reports.
    apply_manifest(pp_resize, catch_failures: true)

    # 5. Re-activate from fstab exactly as a reboot would. With the current
    #    provider mkswap has regenerated the UUID, so the fstab UUID entry no
    #    longer resolves and swap fails to come back.
    run_shell('swapoff -a')
    run_shell('swapon -a || true')
    active = run_shell('swapon --show --noheadings').stdout.strip
    failure = "swap did not reactivate from its fstab UUID (#{uuid}) after the resize; mkswap regenerated the UUID and the fstab/resume=UUID= reference is now stale (issue #372)"
    expect(active).not_to be_empty, failure
  ensure
    run_shell('swapoff -a || true')
    run_shell(%(sed -i '\\|#{fstab_marker}|,+1d' /etc/fstab || true))
    remove_all(pv, vg, lv)
  end
end
