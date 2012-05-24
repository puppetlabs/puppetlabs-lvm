# == Class for lvm
#
# This is an empty class as most of the work is done via resources
#
# = Example:  Added to your site.pp
#
# include lvm
# class lvm::volume { test_lv:
#   vg => 'test_vg',
#   pv => '/dev/sda',
#   fstype => 'ext4',
#   ensure => 'present',
# }

class lvm {

}