# Example storage manifest. All partitions must be created beforehand.


partition { "/dev/sdb2": ensure => present}
partition { "/dev/sdb6": ensure => present}

partition { "/dev/sdb3": ensure => present}
filesystem { "/dev/sdb3": 
 	      block_size => 4096,
	      dir_index => true,
 	      fstab => true,
  	      fs_type => "ext3",
	      label => "my_fs2",
  	      mountpoint => "/misc/foo2"
}

partition { "/dev/sdb5": ensure => present}
partition { "/dev/sdb1": ensure => present}
volumegroup { "my_vg1": physicalvolumes => "/dev/sdb5"}
#volumegroup { "my_vg2": physicalvolumes => ["/dev/sdb5", "/dev/sdb1"]}
logicalvolume { "/dev/my_vg1/my_lv10": size => 20971520}
logicalvolume { "/dev/my_vg1/new_lv1": size => 20971520}
logicalvolume { "/dev/my_vg1/new_lv3": size => 20971520}
filesystem { "/dev/my_vg1/my_lv10":
 	      block_size => 4096, ensure => present,
	      dir_index => false,
 	      fstab => true,
  	      fs_type => "ext3",
	      label => "my_fs1",
  	      mountpoint => "/misc/foo11"
}
filesystem { "/dev/my_vg1/new_lv3":
 	      block_size => 4096, ensure => present,
	      dir_index => false,
 	      fstab => true,
  	      fs_type => "ext2",
	      label => "my_fs3",
  	      mountpoint => "/misc/foo3"
}
filesystem { "/dev/my_vg1/new_lv1":
 	      block_size => 4096,
	      dir_index => true,
 	      fstab => false,
  	      fs_type => "ext3",
	      label => "my_fs4",
  	      mountpoint => absent
}


partition { "/dev/sdb7": ensure => present}
partition { "/dev/sdb10": ensure => present}
mdraid { "/dev/md12": level => raid5, partitions => ["/dev/sdb7", "/dev/sdb10"]}
filesystem { "/dev/md12": 
 	      block_size => 4096,
	      dir_index => true,
 	      fstab => true,
  	      fs_type => "ext3",
	      label => "raid_fs1",
  	      mountpoint => "/misc/foo6"
}

partition { "/dev/sdb8": ensure => present}
partition { "/dev/sdb9": ensure => present}
mdraid { "/dev/md13": level => raid1, partitions => ["/dev/sdb8", "/dev/sdb9"], ensure => absent}
volumegroup { "my_vg_on_raid": physicalvolumes => "/dev/md13", ensure => absent }
logicalvolume { "/dev/my_vg_on_raid/raidvolume1": size => 20971520, ensure=> absent}
filesystem { "/dev/my_vg_on_raid/raidvolume1": 
 	      block_size => 4096, ensure => absent,
	      dir_index => true,
 	      fstab => true,
  	      fs_type => "ext3",
	      label => "lvm_on_raid",
  	      mountpoint => "/misc/foo5"
}


