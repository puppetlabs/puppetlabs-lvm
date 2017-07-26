# == Define: lvm::logical_volume
#
define lvm::logical_volume (
  $size              = undef,
  $initial_size      = undef,
  $ensure            = present,
  $options           = 'defaults',
  $pass              = '2',
  $dump              = '1',
  $fs_type           = 'ext4',
  $mkfs_options      = undef,
  $mountpath         = "/${name}",
  $mountpath_require = false,
  $mounted           = true,
  $createfs          = true,
  $extents           = undef,
  $stripes           = undef,
  $stripesize        = undef,
  $readahead         = undef,
  $range             = undef,
  $size_is_minsize   = undef,
  $type              = undef,
  $thinpool          = undef,
  $poolmetadatasize  = undef,
  $mirror            = undef,
  $mirrorlog         = undef,
  $no_sync           = undef,
  $region_size       = undef,
  $alloc             = undef,
) {

  validate_bool($mountpath_require)

  if ($name == undef) {
    fail("lvm::logical_volume \$name can't be undefined")
  }

  if ($::kernel == 'AIX') {
    if ($options == 'defaults') {
      $aix_options = 'account=false,log=INLINE,mount=true'
    } else {
      $aix_options = $options
    }
    $lvm_device_path = "/dev/${name}"
  } else {
    $lvm_device_path = "/dev/${volume_group}/${name}"
  }

  if $mountpath_require and $fs_type != 'swap' {
    Mount {
      require => File[$mountpath],
    }
  }

  if $fs_type == 'swap' {
    $mount_title     = $lvm_device_path
    $fixed_mountpath = "swap_${lvm_device_path}"
    $fixed_pass      = 0
    $fixed_dump      = 0
    $mount_ensure    = $ensure ? {
      'absent' => absent,
      default  => present,
    }
  } else {
    $mount_title     = $mountpath
    $fixed_mountpath = $mountpath
    $fixed_pass      = $pass
    $fixed_dump      = $dump
    $mount_ensure    = $ensure ? {
      'absent' => absent,
      default  => $mounted ? {
        true      => mounted,
        false     => present,
      }
    }
  }

  if $ensure == 'present' and $createfs {
    Logical_volume[$name]
    -> Filesystem[$lvm_device_path]
    -> Mount[$mount_title]
  } elsif $ensure != 'present' and $createfs {
    Mount[$mount_title]
    -> Filesystem[$lvm_device_path]
    -> Logical_volume[$name]
  }

  logical_volume { $name:
    ensure           => $ensure,
    volume_group     => $volume_group,
    size             => $size,
    initial_size     => $initial_size,
    stripes          => $stripes,
    stripesize       => $stripesize,
    readahead        => $readahead,
    extents          => $extents,
    range            => $range,
    size_is_minsize  => $size_is_minsize,
    type             => $type,
    thinpool         => $thinpool,
    poolmetadatasize => $poolmetadatasize,
    mirror           => $mirror,
    mirrorlog        => $mirrorlog,
    no_sync          => $no_sync,
    region_size      => $region_size,
    alloc            => $alloc,
  }

  if $createfs {
    if ($::kernel == 'AIX') {
      filesystem { $lvm_device_path:
        ensure       => $ensure,
        device       => $lvm_device_path,
        fs_type      => $fs_type,
        mountpath    => $mountpath,
        initial_size => $initial_size,
        options      => $aix_options,
      }
    } else {
      filesystem { $lvm_device_path:
        ensure  => $ensure,
        fs_type => $fs_type,
        options => $mkfs_options,
      }
    }
  }

  if $createfs or $ensure != 'present' {
    if $fs_type != 'swap' {
      exec { "ensure mountpoint '${fixed_mountpath}' exists":
        path    => [ '/bin', '/usr/bin' ],
        command => "mkdir -p ${fixed_mountpath}",
        unless  => "test -d ${fixed_mountpath}",
        before  => Mount[$mount_title],
      }
    }

    mount { $mount_title:
      ensure  => $mount_ensure,
      name    => $fixed_mountpath,
      device  => $lvm_device_path,
      fstype  => $fs_type,
      options => $options,
      pass    => $fixed_pass,
      dump    => $fixed_dump,
      atboot  => true,
    }
  }
}
