define lvm::logical_volume(
  $volume_group,
  $size              = undef,
  $extents           = undef,
  $encryptionkeyfile = undef,
  $luksdevice        = undef,
  $ensure            = present,
  $options           = 'defaults',
  $fs_type           = 'ext4',
  $mountpath         = "/${name}",
  $mountpath_require = false,
) {
  validate_bool($mountpath_require)

  if $mountpath_require {
    Mount {
      require => File[$mountpath],
    }
  }

  $mount_ensure = $ensure ? {
    'absent' => absent,
    default  => mounted,
  }
  $device = $encryptionkeyfile ? {
    undef   => "/dev/${volume_group}/${name}",
    default => "/dev/mapper/enc-${volume_group}-${name}",
  }

  if $ensure == 'present' {
    Logical_volume[$name] ->
    Filesystem[$device] ->
    Mount[$mountpath]
  } else {
    Mount[$mountpath] ->
    Filesystem[$device] ->
    Logical_volume[$name]
  }

  logical_volume { $name:
    ensure            => $ensure,
    volume_group      => $volume_group,
    size              => $size,
    extents           => $extents,
    encryptionkeyfile => $encryptionkeyfile,
  }

  filesystem {$device:
    ensure  => $ensure,
    fs_type => $fs_type,
  }

  exec { "ensure mountpoint '${mountpath}' exists":
    path    => [ '/bin', '/usr/bin' ],
    command => "mkdir -p ${mountpath}",
    unless  => "test -d ${mountpath}",
  } ->
  mount {$mountpath:
    ensure  => $mount_ensure,
    device  => $device,
    fstype  => $fs_type,
    options => $options,
    pass    => 2,
    dump    => 1,
    atboot  => true,
  }

}
