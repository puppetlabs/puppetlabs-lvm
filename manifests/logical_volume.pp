# == Define: lvm::logical_volume
#
define lvm::logical_volume (
  $volume_group,
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
  $createfs          = true,
  $extents           = undef,
  $stripes           = undef,
  $stripesize        = undef,
  $readahead         = undef,
  $range             = undef,
  $type              = undef,
) {

  validate_bool($mountpath_require)

  if ($name == undef) {
    fail("lvm::logical_volume \$name can't be undefined")
  }

  if $mountpath_require {
    Mount {
      require => File[$mountpath],
    }
  }

  $mount_ensure = $ensure ? {
    'absent' => absent,
    default  => mounted,
  }

  if $ensure == 'present' and $createfs {
    Logical_volume[$name] ->
    Filesystem["/dev/${volume_group}/${name}"] ->
    Mount[$mountpath]
  } elsif $ensure != 'present' and $createfs {
    Mount[$mountpath] ->
    Filesystem["/dev/${volume_group}/${name}"] ->
    Logical_volume[$name]
  }

  logical_volume { $name:
    ensure       => $ensure,
    volume_group => $volume_group,
    size         => $size,
    initial_size => $initial_size,
    stripes      => $stripes,
    stripesize   => $stripesize,
    readahead    => $readahead,
    extents      => $extents,
    range        => $range,
    type         => $type,
  }

  if $createfs {
    filesystem { "/dev/${volume_group}/${name}":
      ensure  => $ensure,
      fs_type => $fs_type,
      options => $mkfs_options,
    }
  }

  if $createfs or $ensure != 'present' {
    exec { "ensure mountpoint '${mountpath}' exists":
      path    => [ '/bin', '/usr/bin' ],
      command => "mkdir -p ${mountpath}",
      unless  => "test -d ${mountpath}",
    } ->
    mount { $mountpath:
      ensure  => $mount_ensure,
      device  => "/dev/${volume_group}/${name}",
      fstype  => $fs_type,
      options => $options,
      pass    => $pass,
      dump    => $dump,
      atboot  => true,
    }
  }
}
