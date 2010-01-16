define volume($vg, $pv, $fstype, $size) {
    physical_volume { $pv: ensure => present}
    volume_group { $vg: ensure => present, physical_volume => $pv}
    logical_volume { $lv: ensure => present, volume_group => $vg, fstype => $fstype, size => $size}
}
