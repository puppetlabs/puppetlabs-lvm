# outputs:
# lvm_support: yes/no (based on "vgs" command presence)
# lvm_pvs: [0-9]+
# lvm_vgs: [0-9]+
# lvm_pv_[0-9]+: physical volume name
# lvm_vg_[0-9]+: volume group name

# Generic LVM support
Facter.add('lvm_support') do
  confine :kernel => :linux

  vgdisplay =  Facter::Util::Resolution.exec('which vgs')
  if vgdisplay.nil?
    setcode { 'no' }
  else
    setcode { 'yes' }
  end
end

# Default to no
Facter.add('lvm_support') do
  setcode { 'no' }
end

# VGs
vg_list = []
Facter.add('lvm_vgs') do
  confine :lvm_support => :yes
  vgs = Facter::Util::Resolution.exec('vgs -o name --noheadings 2>/dev/null')
  if vgs.nil?
    setcode { 0 }
  else
    vg_list = vgs.split
    setcode { vg_list.length }
  end
end

vg_num = 0
vg_list.each do |vg|
  Facter.add("lvm_vg_#{vg_num}") { setcode { vg } }
  vg_num += 1
end

# PVs
pv_list = []
Facter.add('lvm_pvs') do
  confine :lvm_support => :yes
  pvs = Facter::Util::Resolution.exec('pvs -o name --noheadings 2>/dev/null')
  if pvs.nil?
    setcode { 0 }
  else
    pv_list = pvs.split
    setcode { pv_list.length }
  end
end

pv_num = 0
pv_list.each do |pv|
  Facter.add("lvm_pv_#{pv_num}") { setcode { pv } }
  pv_num += 1
end
