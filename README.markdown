
Puppet LVM Module
=================

Provides Logical Resource Management (LVM) features for Puppet.

History
-------
2011-08-30 : matthaus

  * Version 0.1.0 : Refactor tests, update readme, repackage for module forge

2011-08-02 : zyv

  * Make it possible to omit the file system type for lmv::volume

2011-07-12 : frimik

  * Allow filesystem type to accept parameters [:options]

2011-06-30 : windowsrefund

  * lvm::volume now uses defined() in order to avoid declaring duplicate
    physical_volume and/or volume_group resources.

  * logical_volume provider now calls dmsetup when removing a volume.

Usage
-----

This module provides four resource types (and associated providers):
`volume_group`, `logical_volume`, `physical_volume`, and `filesystem`.

The basic dependency graph needed to define a working logical volume
looks something like:

    filesystem -> logical_volume -> volume_group -> physical_volume(s)

Here's a simple working example:

    physical_volume { "/dev/hdc":
        ensure => present
    }
    volume_group { "myvg":
        ensure => present,
        physical_volumes => "/dev/hdc"
    }
    logical_volume { "mylv":
        ensure => present,
        volume_group => "myvg",
        size => "20G"
    }
    filesystem { "/dev/myvg/mylv":
        ensure => present,
        fs_type => "ext3",
        options => '-b 4096 -E stride=32,stripe-width=64'
    }

This simple 1 physical volume, 1 volume group, 1 logical volume case
is provided as a simple `volume` definition, as well.  The above could
be shortened to be:

    volume("myvg", "/dev/hdc", "mylv", "ext3", "20G")

Except that in the latter case you cannot specify create options.
=======
If you want to omit the file system type, but still specify the size of the
logical volume, i.e. in the case if you are planning on using this logical
volume as a swap partition or a block device for a virtual machine image, you
need to use a hash to pass the parameters to the definition.

If you need a more complex configuration, you'll need to build the
resources out yourself.

Limitations
-----------

### Namespacing

Due to puppet's lack of composite keys for resources, you currently
cannot define two `logical_volume` resources with the same name but
a different `volume_group`.

### Removing Physical Volumes

You should not remove a `physical_volume` from a `volume_group`
without ensuring the physical volume is no longer in use by a logical
volume (and possibly doing a data migration with the `pvmove` executable).

Removing a `physical_volume` from a `volume_group` resource will cause the
`pvreduce` to be executed -- no attempt is made to ensure `pvreduce`
does not attempt to remove a physical volume in-use.

### Resizing Logical Volumes

Logical volume size can be extended, but not reduced -- this is for
safety, as manual intervention is probably required for data
migration, etc.

Contributors
=======
Bruce Williams <bruce@codefluency.com>

Daniel Kerwin <github@reductivelabs.com>

Luke Kanies <luke@reductivelabs.com>

Matthaus Litteken <matthaus@puppetlabs.com>

Michael Stahnke <stahnma@puppetlabs.com>

Mikael Fridh <frimik@gmail.com>

Tim Hawes <github@reductivelabs.com>

Yury V. Zaytsev <yury@shurup.com>

csschwe <github@reductivelabs.com>

root <root@localhost.localdomain>

windowsrefund <windowsrefund@gmail.com>
