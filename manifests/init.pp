class lvm (
  $manage_package = $::lvm::params::manage_package,
  $package_name   = $::lvm::params::package_name,
  $package_ensure = $::lvm::params::package_ensure,
  $mountpoints    = $::lvm::params::mountpoints,
  $volume_groups  = $::lvm::params::volume_groups,
) inherits ::lvm::params {

  validate_hash($volume_groups)
  validate_hash($mountpoints)
  validate_bool($manage_package)
  validate_string($package_name)

  contain '::lvm::install'
  contain '::lvm::config_mountpoints'
  contain '::lvm::config_volumes'

  Class ['::lvm::install'] ->
  Class ['::lvm::config_mountpoints'] ->
  Class ['::lvm::config_volumes']
}
