  package { "lvm2":
    ensure => "installed"
  }


  #-----------------------------------------------------------------
  # LVM (Logical Volume Manager) mirrors in puppet by Martin Wangel.
  # Tested locally, and with Amazon EBS volumes on EC2 instances.
  #-----------------------------------------------------------------
  $lvm_file_system="ext4"              # ext4 or xfs, xfs can not be resized by this version of this puppet module
  $vgname="mmvg"                       # name of Volume Group
  $lvname="mmlv"                       # name of Logical Volume
  $devices=["/dev/sdb1","/dev/sdb2"]   # Physical Devices
  $lv_fs_size="2G"                     # Size of Logical Volume

  physical_volume { [$devices]:
      ensure => present
  }
  volume_group { "${vgname}":
      ensure => present,
      physical_volumes => $devices,
      require =>  [ Physical_volume[$devices] ]
  } ->
  logical_volume { "${lvname}":
      ensure => present,
      volume_group => $vgname,
      size => $lv_fs_size,
      mirror => 1,
      mirrorlog => core,
      region_size => 4,
      alloc => normal,
      no_sync => 1
  } ->
  filesystem { "/dev/${vgname}/${lvname}":
      ensure => present,
      fs_type => $lvm_file_system,
  } ->
  mount { "lvm-${vgname}-${lvname}":
    name    => "/u",
    ensure  => mounted,
    device  => "/dev/${vgname}/${lvname}",
    fstype  => $lvm_file_system,
    options => "defaults"
  }