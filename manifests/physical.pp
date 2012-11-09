define lvm::physical($ensure = 'present') {
  if ! defined(Physical_volume[$title]) {
    physical_volume { $title: ensure => $ensure }
  }
}
