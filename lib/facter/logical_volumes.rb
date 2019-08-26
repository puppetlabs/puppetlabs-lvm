Facter.add(:logical_volumes) do
  # Fact should be confined to only linux servers that have the lvs command
  confine do
    Facter.value('kernel') == 'Linux' &&
    Facter::Core::Execution.which('lvs')
  end

  setcode do
    # Require the helper methods to reduce duplication
    require 'puppet_x/lvm/output'

    # List columns here that can be passed to the lvs -o command. Dont't
    # include things in here that might be bland as we currently can't deal
    # with them
    columns = [
      'lv_uuid',
      'lv_name',
      'lv_path',
      'lv_attr',
      'lv_size',
    ]
    lvm_version = Gem::Version.new(Facter.value(:lvm_version))
    columns.push('lv_active') if lvm_version >= Gem::Version.new('2.02.99')
    columns.push('lv_full_name', 'lv_dm_path', 'lv_permissions') if lvm_version >= Gem::Version.new('2.02.108')
    columns.push('lv_layout', 'lv_role') if lvm_version >= Gem::Version.new('2.02.110')

    output = Facter::Core::Execution.exec("lvs -o #{columns.join(',')}  --noheading --nosuffix")
    Puppet_X::LVM::Output.parse('lv_name', columns, output)
  end
end
