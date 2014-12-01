# == Define: lvm::logical_volume
#
define lvm::logical_volume (
  $volume_group,
  $size,
  $ensure            = present,
  $options           = 'defaults',
  $fs_type           = 'ext4',
  $mountpath         = "/${name}",
  $mountpath_require = false,
  # pass needs to be a parameter for managing root (/) volume
  $pass              = '2'
) {

  validate_bool($mountpath_require)

  if $mountpath_require {
    # Without this file mountpath resource, catalog runs fail for us on CentOS 6.5
    file { "$mountpath":
      ensure => directory,
    }

    Mount {
      require => File[$mountpath],
    }
  }

  $mount_ensure = $ensure ? {
    'absent' => absent,
    default  => mounted,
  }

  if $ensure == 'present' {
    Logical_volume[$name] ->
    Filesystem["/dev/${volume_group}/${name}"] ->
    Mount[$mountpath]
  } else {
    Mount[$mountpath] ->
    Filesystem["/dev/${volume_group}/${name}"] ->
    Logical_volume[$name]
  }

  logical_volume { $name:
    ensure       => $ensure,
    volume_group => $volume_group,
    size         => $size,
  }

  filesystem { "/dev/${volume_group}/${name}":
    ensure  => $ensure,
    fs_type => $fs_type,
  }
   
  # Required, at least on our CentOS 6.5 build or Puppet errors out when trying to run mkdir or test
  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

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
    dump    => 1,
    atboot  => true,
  }
}
