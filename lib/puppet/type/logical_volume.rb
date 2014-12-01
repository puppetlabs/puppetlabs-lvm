Puppet::Type.newtype(:logical_volume) do
  ensurable

  newparam(:name) do
    desc "The name of the logical volume.  This is the unqualified name and will be
            automatically added to the volume group's device path (e.g., '/dev/$vg/$lv')."
    isnamevar
    validate do |value|
      if value.include?(File::SEPARATOR)
        raise ArgumentError, "Volume names must be entirely unqualified"
      end
    end
  end

  newparam(:volume_group) do
    desc "The volume group name associated with this logical volume.  This will automatically
            set this volume group as a dependency, but it must be defined elsewhere using the
            volume_group resource type."
  end

  newparam(:initial_size) do
    desc "The initial size of the logical volume. This will only apply to newly-created volumes"
    validate do |value|
      unless value =~ /^[0-9]+(\.[0-9]+)?[KMGTPE]/i
        raise ArgumentError , "#{value} is not a valid logical volume size"
      end
    end
  end

  newproperty(:size) do
    desc "The size of the logical volume. Set to undef to use all available space"
    validate do |value|
      unless value =~ /^[0-9]+(\.[0-9]+)?[KMGTPE]/i
        raise ArgumentError , "#{value} is not a valid logical volume size"
      end
    end
  end

  newparam(:extents) do
    desc "The  number of logical extents to allocate for the new logical volume. Set to undef to use all available space"
    validate do |value|
      unless value =~ /^[0-9]+[%(vg|VG|pvs|PVS|free|FREE|origin|ORIGIN)]?/i
        raise ArgumentError , "#{value} is not a valid logical volume extent"
      end
    end
  end

  newparam(:type) do
    desc "Configures the logical volume type. AIX only"
  end

  newparam(:range) do
    desc "Sets the inter-physical volume allocation policy. AIX only"
    validate do |value|
      unless ['maximum','minimum'].include?(value)
        raise ArgumentError, "#{value} is not a valid range"
      end
    end
  end

  newparam(:stripes) do
    desc "The number of stripes to allocate for the new logical volume."
    validate do |value|
      unless value =~ /^[0-9]+/i
        raise ArgumentError , "#{value} is not a valid stripe count"
      end
    end
  end

  newparam(:stripesize) do
    desc "The stripesize to use for the new logical volume."
    validate do |value|
      unless value =~ /^[0-9]+/i
        raise ArgumentError , "#{value} is not a valid stripesize"
      end
    end
  end

  autorequire(:volume_group) do
    @parameters[:volume_group].value
  end
end
