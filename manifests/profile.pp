define lvm::profile (
  $volume,
  $group,
  $filename   = "${name}.profile",
  $allocation = {},
  $activation = {},
) {

  file { "/etc/lvm/profile/${filename}":
    ensure  => file,
    content => template('lvm/profile.erb'),
  }

  exec { "lvm::profile::lvchange::${name}":
    path        => '/sbin:/usr/sbin',
    command     => "lvchange --profile ${name} ${group}/${volume}",
    refreshonly => true,
    subscribe   => File["/etc/lvm/profile/${filename}"],
  }

}

