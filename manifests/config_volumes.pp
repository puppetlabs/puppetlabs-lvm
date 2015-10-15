class lvm::config_volumes (
  $volume_groups = $::lvm::volume_groups,
) {

  create_resources('::lvm::volume_group', $volume_groups)

}
