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
    desc "Configures the logical volume type."
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

  newparam(:readahead) do
    desc "The readahead count to use for the new logical volume."
    validate do |value|
      unless value =~ /^([0-9]+|Auto|None)/i
        raise ArgumentError , "#{value} is not a valid readahead count"
      end
    end
  end

  newparam(:size_is_minsize) do
    desc "Set to true if the 'size' parameter specified, is just the 
            minimum size you need (if the LV found is larger then the size requests
            this is just logged not causing a FAIL)"
    validate do |value|
      unless [:true, true, "true", :false, false, "false"].include?(value)
        raise ArgumentError , "size_is_minsize must either be true or false"
      end
    end
    defaultto :false
  end


  newproperty(:mirror) do
      desc "The number of mirrors of the volume."
      validate do |value|
          unless Integer(value).between?(0, 4)
              raise ArgumentError, "#{value} is not a valid number of mirror copies. Use 0 to un-mirror or 1-4 to set up mirroring."
          end
      end
  end
  newproperty(:mirrorlog) do
      desc "How to store the mirror log (core, disk, mirrored)."
      newvalues( :core, :disk, :mirrored )
  end
  newparam(:alloc) do
      desc "Selects the allocation policy when a command needs to allocate Physical Extents from the Volume Group."
      newvalues( :anywhere, :contiguous, :cling, :inherit, :normal )
  end
  newparam(:no_sync) do
      desc "An optimization in lvcreate, at least on Linux."
  end
  newparam(:region_size) do
      desc "A mirror is divided into regions of this size (in MB), the mirror log uses this granularity to track which regions are in sync. CAN NOT BE CHANGED on already mirrored volume. Take your mirror size in terabytes and round up that number to the next power of 2, using that number as the -R argument."
      validate do |value|
          unless value =~ /^[0-9]+/i
              raise ArgumentError , "#{value} is not a valid region size in MB."
          end
      end
  end


  autorequire(:volume_group) do
    @parameters[:volume_group].value
  end
end
