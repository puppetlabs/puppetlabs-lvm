# == Define: lvm::volume_group
#
# @api public
# Note: Param defaults have been moved to lvm/data using hiera data in modules pattern
define lvm::volume_group (
  Variant[Array, String] $physical_volumes,
  Boolean $createonly               = false,
  Enum['present', 'absent'] $ensure = present,
  Hash $logical_volumes             = { },
  Boolean $followsymlinks           = false,
) {

  if is_hash($physical_volumes) {
    create_resources(
      'lvm::physical_volume',
      $physical_volumes,
      {
        ensure => $ensure,
      }
    )
  }
  else {
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

  create_resources(
    'lvm::logical_volume',
    $logical_volumes,
    {
      ensure       => $ensure,
      volume_group => $name,
    }
  )

}