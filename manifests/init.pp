# == Class: lvm
#
class lvm (
  Enum['installed', 'present', 'latest', 'absent'] $package_ensure = 'installed',
  Hash $volume_groups                                              = {},
) {
  ensure_packages(['lvm2'], {'ensure' => $package_ensure})
  create_resources('lvm::volume_group', $volume_groups)
}
