# == Define: lvm::physical_volume
#
# @api public
# Note: Param defaults have been moved to lvm/data using hiera data in modules pattern
define lvm::physical_volume (
  Enum['present', 'absent'] $ensure,
  Boolean $force,
  String $unless_vg,
) {

  if ($name == undef) {
    fail("lvm::physical_volume \$name can't be undefined")
  }

  physical_volume { $name:
    ensure    => $ensure,
    force     => $force,
    unless_vg => $unless_vg
  }

}