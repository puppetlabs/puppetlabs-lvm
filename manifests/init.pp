define volume($vg, $pv, $lv, $fstype, $size = undef) {
  physical_volume { $pv: ensure => present }
  volume_group { $vg: ensure => present, physical_volumes => $pv }
  logical_volume { $lv: ensure => present, volume_group => $vg, size => $size }
  filesystem { "/dev/${vg}/${lv}": ensure => $fstype, logical_volume => $lv }
}
