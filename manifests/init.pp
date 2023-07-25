# @param package_ensure ensures package is installed

# @param manage_pkg Boolean (true, false)

# @param volume_groups
#
class lvm (
  Enum['installed', 'present', 'latest', 'absent'] $package_ensure = 'installed',
  Boolean $manage_pkg                                              = false,
  Hash $volume_groups                                              = {},
) {
  if $manage_pkg {
    package { 'lvm2':
      ensure   => $package_ensure,
    }
  }

  $volume_groups.each |String $vg, Hash $vgdata| {
    lvm::volume_group { $vg:
      * => $vgdata,
    }
  }
}
