# frozen_string_literal: true

require 'spec_helper_acceptance'

# RHEL 10 support work for https://github.com/puppetlabs/puppetlabs-lvm/issues/372
#
# The reported bug: resizing a swap logical volume runs `swapoff && mkswap &&
# swapon` (swap branch of lib/puppet/provider/logical_volume/lvm.rb#size=), and
# `mkswap` mints a fresh UUID every run. On an anaconda-installed RHEL 10 host
# swap is referenced by UUID in /etc/fstab and in the `resume=UUID=` kernel
# parameter, so the regenerated UUID orphans those references and swap fails to
# reactivate. On RHEL 9 and earlier swap is referenced by device path, so the
# same operation is harmless.
#
# A *genuine* acceptance test of this must resize the real OS swap on a target
# that carries the anaconda layout (LVM swap referenced by UUID) and observe
# that it breaks -- fabricating an fstab entry ourselves would only prove that
# our own fabrication broke, not that the deployed condition breaks.
#
# This spec is the first step: it runs ONLY on the provisioned RHEL/EL 10 target
# and reports its storage layout, then asserts the prerequisites the genuine
# resize test will depend on:
#   1. an LVM logical volume formatted as swap exists, and
#   2. it is referenced by UUID in /etc/fstab.
#
# If those pass, the provisioned image is anaconda-like and we can evolve this
# into the real red/green resize test. If they fail, the CI log (printed below)
# tells us exactly what the image actually is, so we can switch the RHEL 10
# matrix entry to an anaconda/kickstart-built provider/image instead.
describe 'RHEL 10 swap layout (issue #372 environment probe)' do
  before(:each) do
    skip 'Only runs on the provisioned RHEL/EL 10 target' unless os[:family] == 'redhat' && os[:release].to_s.to_i >= 10
  end

  # grep/awk exit non-zero when they match nothing, which run_shell treats as a
  # failure; `|| true` keeps the command successful so we can assert on stdout.
  def capture(command)
    run_shell("#{command} 2>&1 || true").stdout
  end

  it 'has an anaconda-style LVM swap referenced by UUID' do
    lsblk   = capture('lsblk -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS')
    fstab   = capture('cat /etc/fstab')
    swaps   = capture('swapon --show')
    cmdline = capture('cat /proc/cmdline')
    lvs     = capture('lvs')
    vgs     = capture('vgs')
    memfree = capture('free -h')

    # Emit the full picture so it is visible in the CI log regardless of pass/fail.
    puts <<~REPORT
      ============================ RHEL 10 storage probe ============================
      os                : #{os[:family]} #{os[:release]} (#{os[:arch]})
      ------------------------------- lsblk -----------------------------------------
      #{lsblk}
      ------------------------------- /etc/fstab ------------------------------------
      #{fstab}
      ------------------------------- swapon --show ---------------------------------
      #{swaps}
      ------------------------------- /proc/cmdline ---------------------------------
      #{cmdline}
      ------------------------------- lvs -------------------------------------------
      #{lvs}
      ------------------------------- vgs -------------------------------------------
      #{vgs}
      ------------------------------- free ------------------------------------------
      #{memfree}
      ===============================================================================
    REPORT

    # Prerequisite 1: an LVM logical volume formatted as swap.
    lvm_swap = capture("lsblk -rno NAME,TYPE,FSTYPE | awk '$2 == \"lvm\" && $3 == \"swap\" { print $1 }'").strip
    # Prerequisite 2: that swap is referenced by UUID in /etc/fstab.
    fstab_swap_by_uuid = capture(%(grep -E '^[[:space:]]*UUID=[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+swap' /etc/fstab)).strip
    # Nice-to-have context: hibernation resume reference (not asserted, just reported).
    resume = capture(%(grep -oE 'resume=[^[:space:]]+' /proc/cmdline)).strip
    puts "resume= kernel parameter: #{resume.empty? ? '(none)' : resume}"

    aggregate_failures 'anaconda LVM swap prerequisites' do
      expect(lvm_swap).not_to(be_empty,
                              'No LVM logical volume of type swap found on the RHEL 10 target. ' \
                              'This image is not an anaconda-style install with LVM swap; the genuine ' \
                              'resize test cannot run here -- switch the RHEL 10 matrix entry to a ' \
                              'kickstart/anaconda-built provider/image. See the probe output above.')
      expect(fstab_swap_by_uuid).not_to(be_empty,
                                        'Swap is not referenced by UUID in /etc/fstab on the RHEL 10 target. ' \
                                        'The issue #372 failure condition is absent; see the probe output above.')
    end
  end
end
