# == Define: lvm::volume_group
#
define lvm::volume_group (
  $physical_volumes,
  $createonly       = false,
  $ensure           = present,
  $logical_volumes  = {},
  $vg_name          = $name,
) {

  validate_hash($logical_volumes)

  if ($name == undef) {
    fail("lvm::volume_group \$name can't be undefined")
  }

  if is_hash($physical_volumes) {
    create_resources(
      'lvm::physical_volume',
      $physical_volumes,
      {
        ensure           => $ensure,
      }
    )
  }
  else {
    physical_volume { $physical_volumes:
      ensure => $ensure,
    }
  }


  volume_group { $vg_name:
    ensure           => $ensure,
    createonly       => $createonly,
    physical_volumes => $physical_volumes,
  }

  create_resources(
    'lvm::logical_volume',
    $logical_volumes,
    {
      ensure       => $ensure,
      volume_group => $vg_name,
    }
  )
}
