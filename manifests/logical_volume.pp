# == Define: lvm::logical_volume
#
# @api public
# Note: Param defaults have been moved to lvm/data using hiera data in modules pattern
define lvm::logical_volume (
  Variant[Enum['anywhere', 'contiguous', 'cling', 'inherit', 'normal'], Optional] $alloc,
  Boolean $createfs,
  String $dump,
  Enum['absent', 'present'] $ensure,
  Optional[String] $extents,
  String $fs_type,
  Optional[String] $group,
  Optional[String] $initial_size,
  Optional[Integer] $mirror,
  Variant[Enum['core', 'disk', 'mirrored'], Optional] $mirrorlog,
  Optional[String] $mkfs_options,
  Optional[String] $mode,
  Boolean $mounted,
  Boolean $mountpath_require,
  Optional[Boolean] $no_sync,
  String $options,
  Optional[String] $owner,
  String $pass,
  Optional[String] $poolmetadatasize,
  Optional[String] $range,
  Optional[String] $readahead,
  Optional[String] $region_size,
  Optional[String] $size,
  Optional[Boolean] $size_is_minsize,
  Optional[Integer] $stripes,
  Optional[Integer] $stripesize,
  Boolean $thinpool,
  Optional[String] $type,
  String $volume_group,
  Variant[Enum['/'], Stdlib::Absolutepath] $mountpath = "/${name}",
) {

  $lvm_device_path = "/dev/${volume_group}/${name}"

  if $mountpath_require and $fs_type != 'swap' {

    file { $mountpath:
      ensure => directory,
      group  => $group,
      owner  => $owner,
      mode   => $mode,
    }

    Mount {
      require => File[$mountpath],
    }
  }

  if $fs_type == 'swap' {
    $mount_title = $lvm_device_path
    $fixed_mountpath = "swap_${lvm_device_path}"
    $fixed_pass = 0
    $fixed_dump = 0
    $mount_ensure = $ensure ? {
      'absent' => absent,
      default  => present,
    }
  } else {
    $mount_title = $mountpath
    $fixed_mountpath = $mountpath
    $fixed_pass = $pass
    $fixed_dump = $dump
    $mount_ensure = $ensure ? {
      'absent' => absent,
      default  => $mounted ? {
        true  => mounted,
        false => present,
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
    alloc            => $alloc
  }

  if $createfs {
    filesystem { $lvm_device_path:
      ensure  => $ensure,
      fs_type => $fs_type,
      options => $mkfs_options,
    }
  }

  if $createfs or $ensure != 'present' {
    if $fs_type == 'swap' {
      if $ensure == 'present' {
        exec { "swapon for '${mount_title}'":
          path      => [ '/bin', '/usr/bin', '/sbin' ],
          command   => "swapon ${lvm_device_path}",
          unless    => "grep `readlink -f ${lvm_device_path}` /proc/swaps",
          subscribe => Mount[$mount_title],
        }
      } else {
        exec { "swapoff for '${mount_title}'":
          path    => [ '/bin', '/usr/bin', '/sbin' ],
          command => "swapoff ${lvm_device_path}",
          onlyif  => "grep `readlink -f ${lvm_device_path}` /proc/swaps",
          notify  => Mount[$mount_title],
        }
      }
    } else {
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