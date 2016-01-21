test_name 'FM-4614 - C97171 - Install the LVM module'

step 'Install LVM Module Dependencies'
on(master, puppet('module install puppetlabs-stdlib'))

step 'Install LVM Module'
on(master, puppet('module install puppetlabs-lvm'))
