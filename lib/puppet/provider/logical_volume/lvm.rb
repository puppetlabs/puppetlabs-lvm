Puppet::Type.type(:logical_volume).provide :lvm do
    desc "Manages LVM logical volumes"

    commands :lvcreate   => 'lvcreate',
             :lvremove   => 'lvremove',
             :lvextend   => 'lvextend',
             :lvs        => 'lvs',
             :resize2fs  => 'resize2fs',
             :umount     => 'umount',
             :blkid      => 'blkid',
             :dmsetup    => 'dmsetup',
             :lvconvert  => 'lvconvert',
             :lvdisplay  => 'lvdisplay'

    optional_commands :xfs_growfs => 'xfs_growfs',
                      :resize4fs  => 'resize4fs'

    def self.instances
      get_logical_volumes.collect do |logical_volumes_line|
        logical_volumes_properties = get_logical_volume_properties(logical_volumes_line)
        new(logical_volumes_properties)
      end
    end

    def self.get_logical_volumes
      full_lvs_output = lvs.split("\n")

      # Remove first line
      logical_volumes = full_lvs_output.drop(1)

      logical_volumes
    end

    def self.get_logical_volume_properties(logical_volumes_line)
      logical_volumes_properties = {}

      # lvs output formats thus:
      # LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert

      # Split on spaces
      output_array = logical_volumes_line.gsub(/\s+/m, ' ').strip.split(" ")

      # Assign properties based on headers
      # Just doing name for now...
      logical_volumes_properties[:ensure]     = :present
      logical_volumes_properties[:name]       = output_array[0]

      logical_volumes_properties
    end

    def create
        args = ['-n', @resource[:name]]
        if @resource[:size]
            args.push('--size', @resource[:size])
        elsif @resource[:initial_size]
            args.push('--size', @resource[:initial_size])
        end
        if @resource[:extents]
            args.push('--extents', @resource[:extents])
        end

        if !@resource[:extents] and !@resource[:size] and !@resource[:initial_size]
            args.push('--extents', '100%FREE')
        end

        if @resource[:stripes]
            args.push('--stripes', @resource[:stripes])
        end

        if @resource[:stripesize]
            args.push('--stripesize', @resource[:stripesize])
        end


        if @resource[:mirror]
            args.push('--mirrors', @resource[:mirror])
            if @resource[:mirrorlog]
                args.push('--mirrorlog', @resource[:mirrorlog])
            end
            if @resource[:region_size]
                args.push('--regionsize', @resource[:region_size])
            end
            if @resource[:no_sync]
                args.push('--nosync')
            end
        end

        if @resource[:alloc]
            args.push('--alloc', @resource[:alloc])
        end


        if @resource[:readahead]
            args.push('--readahead', @resource[:readahead])
        end

        if @resource[:persistent]
            # if persistent param is true, set arg to "y", otherwise set to "n"
            args.push('--persistent', [:true, true, "true"].include?(@resource[:persistent]) ? 'y' : 'n')
        end

        if @resource[:minor]
            args.push('--minor', @resource[:minor])
        end

        args << @resource[:volume_group]
        lvcreate(*args)
    end

    def destroy
        name_escaped = "#{@resource[:volume_group].gsub('-','--')}-#{@resource[:name].gsub('-','--')}"
        dmsetup('remove', name_escaped)
        lvremove('-f', path)
    end

    def exists?
        lvs(@resource[:volume_group]) =~ lvs_pattern
    end

    def size
        if @resource[:size] =~ /^\d+\.?\d{0,2}([KMGTPE])/i
            unit = $1.downcase
        end

        raw = lvs('--noheading', '--unit', unit, path)

        if raw =~ /\s+(\d+)\.(\d+)#{unit}/i
            if $2.to_i == 00
                return $1 + unit.capitalize
            else
                return $1 + '.' + $2 + unit.capitalize
            end
        end
    end

    def size=(new_size)
        lvm_size_units = { "K" => 1, "M" => 1024, "G" => 1048576, "T" => 1073741824, "P" => 1099511627776, "E" => 1125899906842624 }
        lvm_size_units_match = lvm_size_units.keys().join('|')

        current_size = size()
        
        ## Get the extend size
        if lvs('--noheading', '-o', 'vg_extent_size', '--units', 'k', path) =~ /\s+(\d+)\.\d+k/i
            vg_extent_size = $1.to_i
        end

        # Get the current size and convert it to Kb
        if current_size =~ /(\d+\.{0,1}\d{0,2})(#{lvm_size_units_match})/i
            current_size_value = $1.to_f
            current_size_unit  = $2.upcase
            current_size_kb = current_size_value * lvm_size_units[current_size_unit]
        end

        # Get the new size, convert it to Kb and round according to vg_extent_size
        # so the values current_size and new_size are comparable
        if new_size =~ /(\d+\.{0,1}\d{0,2})(#{lvm_size_units_match})/i
            new_size_value = $1.to_f
            new_size_unit  = $2.upcase
            new_size_kb = new_size_value * lvm_size_units[new_size_unit]

            if new_size_kb % vg_extent_size == 0 then
                new_rounded_size_kb = new_size_kb
            else
                new_rounded_size_kb = vg_extent_size * (1 + (new_size_kb / vg_extent_size).floor)
                debug("New LV size including VG Extent size rounding was calculated to: #{ sprintf('%.2f', new_rounded_size_kb/lvm_size_units[new_size_unit]) }#{new_size_unit}")
            end
        end

        ## Verify that it's an extension: Reduce is potentially dangerous and should be done manually
        if current_size_kb > new_rounded_size_kb then
            if @resource[:size_is_minsize] == :true or @resource[:size_is_minsize] == true or @resource[:size_is_minsize] == 'true'
                info( "Logical volume already has minimum size of #{new_size} (currently #{current_size})" )
            else
                fail( "Decreasing the size requires manual intervention (#{new_size} < #{current_size})" )
            end
        elsif current_size_kb < new_rounded_size_kb then
            # LV is going to be extended
            info( "Changing logical volume size to #{ sprintf('%.2f', new_rounded_size_kb/lvm_size_units[new_size_unit]) }#{new_size_unit}" )
            lvextend( '-L', "#{new_rounded_size_kb}K", path) || fail( "lvextend command failed." )

            blkid_type = blkid(path)
            if command(:resize4fs) and blkid_type =~ /\bTYPE=\"(ext4)\"/
              resize4fs( path) || fail( "Cannot resize file system to size #{new_size} because resize2fs failed." )
            elsif blkid_type =~ /\bTYPE=\"(ext[34])\"/
              resize2fs( path) || fail( "Cannot resize file system to size #{new_size} because resize2fs failed." )
            elsif blkid_type =~ /\bTYPE=\"(xfs)\"/
              xfs_growfs( path) || fail( "Cannot resize filesystem to size #{new_size} because xfs_growfs failed." )
            end
        else
            # LV doesn't change
            debug( "The size of logical volume doesn't change." )
        end
    end


    # Look up the current number of mirrors (0=no mirroring, 1=1 spare, 2=2 spares....). Return the number as string.
    def mirror
        raw = lvdisplay( path )
        # If the first attribute bit is "m" or "M" then the LV is mirrored.
        if raw =~ /Mirrored volumes\s+(\d+)/im
            # Minus one because it says "2" when there is only one spare. And so on.
            n = ($1.to_i)-1
            #puts " current mirrors: #{n}"
            return n.to_s
        end
        return 0.to_s
    end

    def mirror=( new_mirror_count )
        current_mirrors = mirror().to_i
        if new_mirror_count.to_i != current_mirrors
            puts "Change mirror from #{current_mirrors} to #{new_mirror_count}..."
            args = ['-m', new_mirror_count]
            if @resource[:mirrorlog]
                args.push( '--mirrorlog', @resource[:mirrorlog] )
            end

            # Region size cannot be changed on an existing mirror (not even when changing to zero mirrors).

            if @resource[:alloc]
                args.push( '--alloc', @resource[:alloc] )
            end
            args.push( path )
            lvconvert( *args )
        end
    end

    # Location of the mirror log. Empty string if mirror==0, else "mirrored", "disk" or "core".
    def mirrorlog
        vgname = "#{@resource[:volume_group]}"
        lvname = "#{@resource[:name]}"
        raw = lvs('-a', '-o', '+devices', vgpath)

        if mirror().to_i > 0
            if raw =~ /\[#{lvname}_mlog\]\s+#{vgname}\s+/im
                if raw =~ /\[#{lvname}_mlog\]\s+#{vgname}\s+mw\S+/im #attributes start with "m" or "M"
                    return "mirrored"
                else
                    return "disk"
                end
            else
                return "core"
            end
        end
        return nil
    end

    def mirrorlog=( new_mirror_log_location )
        # It makes no sense to change this unless we use mirrors.
        mirror_count = mirror().to_i
        if mirror_count.to_i > 0
            current_log_location = mirrorlog().to_s
            if new_mirror_log_location.to_s != current_log_location
                #puts "Change mirror log location to #{new_mirror_log_location}..."
                args = [ '--mirrorlog', new_mirror_log_location ]
                if @resource[:alloc]
                    args.push( '--alloc', @resource[:alloc] )
                end
                args.push( path )
                lvconvert( *args )
            end
        end
    end




    private

    def lvs_pattern
        /\s+#{Regexp.quote @resource[:name]}\s+/
    end

    def path
        "/dev/#{@resource[:volume_group]}/#{@resource[:name]}"
    end

    # Device path of only the volume group (does not include the logical volume).
    def vgpath
        "/dev/#{@resource[:volume_group]}"
    end

end
