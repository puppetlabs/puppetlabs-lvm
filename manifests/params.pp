class lvm::params {

  case $::kernel {
    'Linux': {
      $manage_package = false
      $package_name   = 'lvm2'
      $package_ensure = 'installed'
      $mountpoints    = {}
      $volume_groups  = {}
    }

  default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }
}
