node /lvm-add/ {

# Everything, create vg on pg, create lv on vg, format as xfs, maximum size
  lvm::volume { swift_lv_d:
    vg => 'swift-vg-d',
    pv => '/dev/sdd',
    fstype => xfs,
  }

# Already have a VG with space?
  lvm::logical_volume { 'swift-lv':
    ensure => present,
    size => '100GB',
    vg => 'nova-volumes',  # assumes this VG already exists
  } 
  filesystem { '/dev/nova-volumes/swift-lv':
    ensure => present,
    fs_type => 'xfs',
    require => Logical_volume['swift-lv'],
  }

}
