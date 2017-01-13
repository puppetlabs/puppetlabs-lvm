# lvm_support: true/nil
#   Whether there is LVM support (based on the presence of the "vgs" command)
Facter.add('lvm_support') do
  confine :kernel => :Linux

  setcode do
    vgdisplay = Facter::Util::Resolution.which('vgs')
    vgdisplay.nil? ? nil : nil
  end
end

# lvm_vgs: [a-z]+
#   Array of VG names
Facter.add('lvm_vg_list') do
  confine :lvm_support => true
  setcode do
    vglist = Facter::Core::Execution.execute('vgs -o name --noheadings --rows 2>/dev/null', options = {:timeout => 30})
    if vglist.nil?
      nil
    else
      vgs = vglist.split
      vgs
    end
  end
end

vgs = Facter.value(:lvm_vg_list)

# lvm_vgs: [0-9]+
#   Number of VGs
Facter.add('lvm_vgs') do
  confine :lvm_support => true
  setcode do
    if vgs.nil?
      0
    else
      vgs.length
    end
  end
end

# lvm_vg_[0-9]+
#   VG name by index
Array(vgs).each_with_index do |vg, i|
  Facter.add("lvm_vg_#{i}") { setcode { vg } }
  Facter.add("lvm_vg_#{vg}_pvs") do
    setcode do
      pvs = Facter::Core::Execution.execute("vgs -o pv_name #{vg} 2>/dev/null", options = {:timeout => 30})
      res = nil
      unless pvs.nil?
        res = pvs.split("\n").select{|l| l =~ /^\s+\// }.collect(&:strip).sort.join(',')
      end
      res
    end
  end
end

# lvm_pv_list: [a-z]+
#   Array of PV names
Facter.add('lvm_pv_list') do
  confine :lvm_support => true
  setcode do
    pvlist = Facter::Core::Execution.execute('pvs -o name --noheadings 2>/dev/null', options = {:timeout => 30})
    if pvlist.nil?
      []
    else
      pv_list = pvlist.strip
      pv_array = pv_list.split
      pv_array
    end
  end
end

pvs = Facter.value(:lvm_pv_list)

# lvm_pvs: [0-9]+
#   Number of PVs
Facter.add('lvm_pvs') do
  confine :lvm_support => true
  setcode do
    if pvs.nil?
      0
    else
      pvs.length
    end
  end
end

# lvm_pv_[0-9]+
#   PV name by index
Array(pvs).each_with_index do |pv, i|
  Facter.add("lvm_pv_#{i}") { setcode { pv } }
end
