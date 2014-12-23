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

    def size(real = false)
        if @resource[:size] =~ /^\d+\.?\d{0,2}([KMGTPE])/i
            unit = $1.downcase
        end

        raw = lvs('--noheading', '--unit', unit, path)

        if raw =~ /\s+(\d+)\.(\d+)#{unit}/i
            if $2.to_i == 00
                current_size = $1 + unit.capitalize
            else
                current_size = $1 + '.' + $2 + unit.capitalize
            end
        end

        # normal (old) behavior is size_is_minsize is not enabled
        if real or !allow_minsize()
            return current_size
        else
            # if we're growing, don't lie because we want to run the commands
            if is_resizeable(current_size, @resource[:size])
                return current_size
            else
                # this check is to avoid emitting the info() message when the
                # size is already at the desired value
                if current_size != @resource[:size]
                    # if size_is_minisize is set and the current size is larger,
                    # lie about our size so we do not trigger a resource change
                    # on every run
                    info( "Logical volume already has a minimum size of #{@resource[:size]} (currently #{current_size})" )
                end

                return @resource[:size]
            end
        end
    end

    def size=(new_size)
        lvm_size_units_match = lvm_size_units.keys().join('|')

        current_size = size(real = true)
        resizeable = is_resizeable(current_size, new_size)

        new_size_bytes, new_size_unit = get_size_parts('\d+', new_size)

        ## Get the extend size
        if lvs('--noheading', '-o', 'vg_extent_size', '--units', 'k', path) =~ /\s+(\d+)\.\d+k/i
            vg_extent_size = $1.to_i
        end

        if not resizeable
            # this is only reachable when size_is_minsize == false
            fail( "Decreasing the size requires manual intervention (#{new_size} < #{current_size})" )
        else
            ## Check if new size fits the extend blocks
            if new_size_bytes * lvm_size_units[new_size_unit] % vg_extent_size != 0
                fail( "Cannot extend to size #{new_size} because VG extent size is #{vg_extent_size} KB" )
            end

            lvextend( '-L', new_size, path) || fail( "Cannot extend to size #{new_size} because lvextend failed." )

            blkid_type = blkid(path)
            if command(:resize4fs) and blkid_type =~ /\bTYPE=\"(ext4)\"/
              resize4fs( path) || fail( "Cannot resize file system to size #{new_size} because resize2fs failed." )
            elsif blkid_type =~ /\bTYPE=\"(ext[34])\"/
              resize2fs( path) || fail( "Cannot resize file system to size #{new_size} because resize2fs failed." )
            elsif blkid_type =~ /\bTYPE=\"(xfs)\"/
              xfs_growfs( path) || fail( "Cannot resize filesystem to size #{new_size} because xfs_growfs failed." )
            end

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

    def is_resizeable(current_size, new_size)
        current_size_bytes, current_size_unit = get_size_parts('\d+\.{0,1}\d{0,2}', current_size)

        new_size_bytes, new_size_unit = get_size_parts('\d+', new_size)

        ## Verify that it's a extension: Reduce is potentially dangerous and should be done manually
        if lvm_size_units[current_size_unit] < lvm_size_units[new_size_unit]
            return true
        elsif lvm_size_units[current_size_unit] > lvm_size_units[new_size_unit]
            if (current_size_bytes * lvm_size_units[current_size_unit]) < (new_size_bytes * lvm_size_units[new_size_unit])
                return true
            end
        elsif lvm_size_units[current_size_unit] == lvm_size_units[new_size_unit]
            if new_size_bytes > current_size_bytes
                return true
            end
        end

        return false
    end

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

    def lvm_size_units
        { "K" => 1, "M" => 1024, "G" => 1048576, "T" => 1073741824, "P" => 1099511627776, "E" => 1125899906842624 }
    end

    def lvm_size_units_match
        lvm_size_units.keys().join('|')
    end

    def get_size_parts(pattern, size)
        if size =~ /(#{pattern})(#{lvm_size_units_match})/i
            bytes = $1.to_i
            unit  = $2.upcase
        end

        return bytes, unit
    end

    def allow_minsize
        return (@resource[:size_is_minsize] == :true or @resource[:size_is_minsize] == true or @resource[:size_is_minsize] == 'true')
    end
end
