# @param physical_volumes The list of physical volumes to be included in the volume group; 
# this will automatically set these as dependencies, but they must be defined elsewhere using the physical_volume resource type.

# @param createonly If set to true the volume group will be created if it does not exist. 
# If the volume group does exist no action will be taken. Defaults to false. Allowed Values:
# true
# false

# @param ensure

# @param logical_volumes 

# @param followsymlinks If set to true all current and wanted values of the physical_volumes property will be followed to their real 
# files on disk if they are in fact symlinks. This is useful to have Puppet determine what the actual PV device is if the property 
# value is a symlink, like '/dev/disk/by-path/xxxx -> ../../sda'. Defaults to false.
#
define lvm::volume_group (
  Variant[Hash, Array, String] $physical_volumes,
  Boolean $createonly               = false,
  Enum['present', 'absent'] $ensure = present,
  Hash $logical_volumes             = {},
  Boolean $followsymlinks           = false,
) {
  if $physical_volumes.is_a(Hash) {
    $physical_volumes.each |String $pv, Hash $pvdata| {
      lvm::physical_volume { $pv:
        ensure => $ensure,
        *      => $pvdata,
      }
    }
  } else {
    physical_volume { $physical_volumes:
      ensure => $ensure,
    }
  }

  volume_group { $name:
    ensure           => $ensure,
    createonly       => $createonly,
    physical_volumes => $physical_volumes,
    followsymlinks   => $followsymlinks,
  }

  $logical_volumes.each |String $lv, Hash $lvdata| {
    lvm::logical_volume { $lv:
      ensure       => $ensure,
      volume_group => $name,
      *            => $lvdata,
    }
  }
}
