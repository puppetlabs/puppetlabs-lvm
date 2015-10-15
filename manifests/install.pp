class lvm::install (
  $manage_package  = $::lvm::manage_package,
  $package_name    = $::lvm::package_name,
  $package_ensure  = $::lvm::package_ensure,
){

  if ($manage_package) {

    package { $package_name :
      ensure => $package_ensure,
    }

  }

}
