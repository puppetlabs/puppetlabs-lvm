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
  $fs_type           = undef,
  $mkfs_options      = undef,
  $mountpath         = undef,
  $mountpath_require = false,
  $mountlv           = false,
  $extents           = undef,
  $stripes           = undef,
  $stripesize        = undef,
  $readahead         = undef,
  $range             = undef,
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

  if $mountlv {
    if $ensure == 'present' {
      Logical_volume[$name] ->
      Filesystem["/dev/${volume_group}/${name}"] ->
      Mount[$mountpath]
    } else {
      Mount[$mountpath] ->
      Filesystem["/dev/${volume_group}/${name}"] ->
      Logical_volume[$name]
    }
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
  } ->

  filesystem { "/dev/${volume_group}/${name}":
    ensure  => $ensure,
    fs_type => $fs_type,
    options => $mkfs_options,
  }

  if $mountlv {
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
