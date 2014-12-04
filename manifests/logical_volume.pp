define lvm::logical_volume(
  $volume_group,
  $size,
  $ensure            = present,
  $options           = 'defaults',
  $fs_type           = 'ext4',
  $pass              = undef,
  $dump              = undef,
  $mountpath         = undef,
  $mountpath_require = false,
) {
  validate_bool($mountpath_require)

  $lvm_device_path = "/dev/${volume_group}/${name}"

  if $fs_type == 'swap' {
    $mount_title      = "${name}"
    $mount_ensure     = 'unmounted'
    # Mount path for swap should be none, should be fixed in puppet?
    $fixed_mountpath  = swap
    $fixed_pass       = 0
    $fixed_dump       = 0
  } else {
    $mount_title     = $mountpath
    $fixed_mountpath = $mountpath ? {
      undef   => "/${name}",
      default => $mountpath
    }
    $mount_ensure = $ensure ? {
      'absent' => absent,
      default  => mounted
    }
    $fixed_pass = $pass ? {
      undef   => 2,
      default => $pass
    }
    $fixed_dump = $dump ? {
      undef   => 1,
      default => $dump
    }
  }

  if $mountpath_require and $fs_type != 'swap' {
    Mount {
      require => File[$fixed_mountpath],
    }
  }


  if $ensure == 'present' {
    Logical_volume[$name] ->
    Filesystem[$lvm_device_path] ->
    Mount[$mount_title]
  } else {
    Mount[$mount_title] ->
    Filesystem[$lvm_device_path] ->
    Logical_volume[$name]
  }

  logical_volume { $name:
    ensure       => $ensure,
    volume_group => $volume_group,
    size         => $size,
  }

  filesystem {$lvm_device_path:
    ensure  => $ensure,
    fs_type => $fs_type,
  }

  if $fs_type != 'swap' {
    exec { "ensure mountpoint '${fixed_mountpath}' exists":
      command => "mkdir -p ${fixed_mountpath}",
      path    => '/bin:/usr/bin',
      unless  => "test -d ${fixed_mountpath}",
      before  => Mount[$mount_title]
    }
  } else {
    if $ensure == 'present' { # if ensure was present mount the swap
      exec {"swapon -a for '${mount_title}'":
        command     => 'swapon -a',
        path        => '/bin:/usr/bin:/sbin',
        refreshonly => true,
        subscribe   => Mount[$mount_title],
      }
    }
  }
  mount {"${mount_title}":
    ensure  => $mount_ensure,
    name    => $fixed_mountpath,
    device  => "${lvm_device_path}",
    fstype  => $fs_type,
    options => $options,
    pass    => $fixed_pass,
    dump    => $fixed_dump,
    atboot  => true,
    alias   => $mount_title,
  }

}

