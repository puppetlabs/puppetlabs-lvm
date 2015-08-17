class lvm::config (
  $mountpoints        = $::lvm::mountpoints,
) {

  if ($mountpoints) {

    $mountpoint_defaults = {
      ensure => directory,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    create_resources(file, $mountpoints, $mountpoint_defaults)
  }

}
