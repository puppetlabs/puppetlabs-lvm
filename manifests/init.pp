# == Class: lvm
#
class lvm (
  $volume_groups = {},
  $version       = 'installed'
) {

  $real_provider = $::osfamily ? {
    'Debian' => 'apt',
    'RedHat' => 'yum'
  }

  package {
    'lvm2':
      ensure   => $version,
      provider => $real_provider
  }

  validate_hash($volume_groups)

  create_resources('lvm::volume_group', $volume_groups)
}
