# == Class: lvm
#
class lvm (
  Enum['installed', 'present', 'latest', 'absent'] $package_ensure = 'installed',
  Hash $volume_groups                                              = {},
) {

  if $package_ensure == 'absent' {
    package { 'lvm2':
      ensure => 'absent',
    }
  } elsif ! defined(Package['lvm2']) {
    package { 'lvm2':
      ensure => $package_ensure,
    }
  }

  create_resources('lvm::volume_group', $volume_groups)
}
