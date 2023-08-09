# frozen_string_literal: true

# lvm_support: true/nil
#   Whether there is LVM support (based on the presence of the "vgs" command)
Facter.add('lvm_support') do
  confine kernel: :linux

  setcode do
    vgdisplay = Facter::Util::Resolution.which('vgs')
    vgdisplay.nil? ? nil : true
  end
end

# lvm_vgs: [0-9]+
#   Number of VGs
vg_list = []
Facter.add('lvm_vgs') do
  confine lvm_support: true

  setcode do
    vgs = Facter::Core::Execution.execute('vgs -o name --noheadings 2>/dev/null', timeout: 30)
    if vgs.nil?
      0
    else
      vg_list = vgs.split
      vg_list.length
    end
  end
end

# lvm_vg_[0-9]+
#   VG name by index
vg_list.each_with_index do |vg, i|
  Facter.add("lvm_vg_#{i}") { setcode { vg } }
  Facter.add("lvm_vg_#{vg}_pvs") do
    setcode do
      pvs = Facter::Core::Execution.execute("vgs -o pv_name #{vg} 2>/dev/null", timeout: 30)
      res = nil
      res = pvs.split("\n").grep(%r{^\s+/}).map(&:strip).sort.join(',') unless pvs.nil?
      res
    end
  end
end

# lvm_pvs: [0-9]+
#   Number of PVs
pv_list = []
Facter.add('lvm_pvs') do
  confine lvm_support: true

  setcode do
    pvs = Facter::Core::Execution.execute('pvs -o name --noheadings 2>/dev/null', timeout: 30)
    if pvs.nil?
      0
    else
      pv_list = pvs.split
      pv_list.length
    end
  end
end

# lvm_pv_[0-9]+
#   PV name by index
pv_list.each_with_index do |pv, i|
  Facter.add("lvm_pv_#{i}") { setcode { pv } }
end
