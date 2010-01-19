define volume($vg, $pv, $lv, $fstype, $size = undef) {
  physical_volume { $pv: ensure => present }
  volume_group { $vg: ensure => present, physical_volume => $pv }
  logical_volume { $lv: ensure => present, volume_group => $vg, size => $size }
  filesystem { "/dev/${vg}/${lv}": fstype => $fstype, size => $size }
}
