# This defined type will create a logical_volume with the name of
# the define and ensure a physical_volume,
# volume_group, and filesystem resource have been
# created on the block device supplied.
#
# @param ensure Can only be set to cleaned, absent or present. A value of present will ensure that the
# physical_volume, volume_group,
# logical_volume, and filesystem resources are
# present for the volume. A value of cleaned will ensure that all
# of the resources are absent Warning this has a high potential
# for unexpected harm use it with caution. A value of absent
# will remove only the logical_volume resource from the system.
# The block device to ensure a physical_volume has been
# created on The volume_group to ensure is created on the
# physical_volume provided by the pv parameter.
#

# @param fstype The type of filesystem to create on the logical
# volume.

# @param pv path to physcial volume

# @param vg value of volume group

# @param size The size the logical_voluem should be.

# @param extents The number of logical extents to allocate for the new logical volume.
# Set to undef to use all available space

# @param yes_flag If set to true, do not prompt for confirmation interactively but always assume the answer yes.

# @param initial_size The initial size of the logical volume.
# This will only apply to newly-created volumes
#
# === Examples
#
# Provide some examples on how to use this type:
#
#   lvm::volume { 'lv_example0':
#     vg     => 'vg_example0',
#     pv     => '/dev/sdd1',
#     fstype => 'ext4',
#     size => '100GB',
#   }
#
# === Copyright
#
# See README.markdown for the module author information.
#
# === License
#
# This file is part of the puppetlabs/lvm puppet module.
#
# puppetlabs/lvm is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation, version 2 of the License.
#
# puppetlabs/lvm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with puppetlabs/lvm. If not, see http://www.gnu.org/licenses/.
#
define lvm::volume (
  Enum['present', 'absent', 'cleaned'] $ensure,
  Stdlib::Absolutepath $pv,
  String[1] $vg,
  Optional[String[1]] $fstype                     = undef,
  Optional[String[1]] $size                       = undef,
  Optional[Variant[String[1], Integer]] $extents  = undef,
  Optional[String[1]] $initial_size               = undef,
  Boolean $yes_flag                               = false,
) {
  if ($name == undef) {
    fail("lvm::volume \$name can't be undefined")
  }

  case $ensure {
    #
    # Clean up the whole chain.
    #
    'cleaned': {
      # This may only need to exist once
      if ! defined(Physical_volume[$pv]) {
        physical_volume { $pv: ensure => present }
      }
      # This may only need to exist once
      if ! defined(Volume_group[$vg]) {
        volume_group { $vg:
          ensure           => present,
          physical_volumes => $pv,
          before           => Physical_volume[$pv],
        }

        logical_volume { $name:
          ensure       => present,
          volume_group => $vg,
          size         => $size,
          initial_size => $initial_size,
          yes_flag     => $yes_flag,
          before       => Volume_group[$vg],
        }
      }
    }
    #
    # Just clean up the logical volume
    #
    'absent': {
      logical_volume { $name:
        ensure       => absent,
        volume_group => $vg,
        size         => $size,
        yes_flag     => $yes_flag,
      }
    }
    #
    # Create the whole chain.
    #
    'present': {
      # This may only need to exist once.  Requires stdlib 4.1 to
      # handle $pv as an array.
      ensure_resource('physical_volume', $pv, { 'ensure' => $ensure })

      # This may only need to exist once
      if ! defined(Volume_group[$vg]) {
        volume_group { $vg:
          ensure           => present,
          physical_volumes => $pv,
          require          => Physical_volume[$pv],
        }
      }

      logical_volume { $name:
        ensure       => present,
        volume_group => $vg,
        size         => $size,
        extents      => $extents,
        yes_flag     => $yes_flag,
        require      => Volume_group[$vg],
      }

      if $fstype != undef {
        filesystem { "/dev/${vg}/${name}":
          ensure  => present,
          fs_type => $fstype,
          require => Logical_volume[$name],
        }
      }
    }
    default: {
      fail ( sprintf('%s%s', 'puppet-lvm::volume: ensure parameter can only ',
      'be set to cleaned, absent or present') )
    }
  }
}
