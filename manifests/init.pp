define lvm::volume($vg, $pv, $fstype = undef, $size = undef, $ensure) {
  case $ensure {
    #
    # Clean up the whole chain.
    #
    cleaned: {
      # This may only need to exist once
      lvm::physical { $pv: }

      # This may only need to exist once
      if ! defined(Volume_group[$vg]) {
        volume_group { $vg:
          ensure           => present,
          physical_volumes => $pv,
          before           => Physical_volume[$pv]
        }

        logical_volume { $name:
          ensure       => present,
          volume_group => $vg,
          size         => $size,
          before       => Volume_group[$vg]
        }
      }
    }
    #
    # Just clean up the logical volume
    #
    absent: {
      logical_volume { $name:
        ensure       => absent,
        volume_group => $vg,
        size         => $size
      }
    }
    #
    # Create the whole chain.
    #
    present: {
      # This may only need to exist once
      lvm::physical { $pv: }

      # This may only need to exist once
      if ! defined(Volume_group[$vg]) {
        volume_group { $vg:
          ensure           => present,
          physical_volumes => $pv,
          require          => Physical_volume[$pv]
        }
      }

      logical_volume { $name:
        ensure       => present,
        volume_group => $vg,
        size         => $size,
        require      => Volume_group[$vg]
      }

      if $fstype != undef {
        filesystem { "/dev/${vg}/${name}":
          ensure  => present,
          fs_type => $fstype,
          require => Logical_volume[$name]
        }
      }

    }
    default: {
      fail ( 'puppet-lvm::volume: ensure parameter can only be set to cleaned, absent or present' )
    }
  }
}
