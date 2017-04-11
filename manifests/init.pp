# == Class: lvm
# @api public
# Note: Param defaults have been moved to lvm/data using hiera data in modules pattern
class lvm (
  Enum['installed', 'present', 'latest', 'absent'] $package_ensure,
  Boolean $manage_pkg,
  Hash $volume_groups,
) {

  if $manage_pkg {
    package { 'lvm2':
      ensure   => $package_ensure
    }
  }

  create_resources('lvm::volume_group', $volume_groups)

}