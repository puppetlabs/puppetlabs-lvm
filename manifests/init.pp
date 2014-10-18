class lvm(
  $volume_groups    = {},
) {
  validate_hash($volume_groups)

  create_resources('lvm::volume_group', $volume_groups)
}
