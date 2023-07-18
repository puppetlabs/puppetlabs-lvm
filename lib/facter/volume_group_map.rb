# frozen_string_literal: true

Facter.add(:volume_group_map) do
  # Fact should be confined to only linux servers that have the vgs command
  confine do
    Facter.value('kernel') == 'Linux' &&
      Facter::Core::Execution.which('vgs')
  end

  setcode do
    Facter.value(:volume_groups).keys.to_h do |vg|
      [
        vg,
        Facter::Core::Execution.exec("vgs -o pv_name #{vg} --noheading --nosuffix")
                               .split("\n")
                               .map(&:strip)
                               .join(','),
      ]
    end
  end
end
