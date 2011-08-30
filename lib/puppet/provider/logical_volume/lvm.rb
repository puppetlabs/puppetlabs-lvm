Puppet::Type.type(:logical_volume).provide :lvm do
    desc "Manages LVM logical volumes"

    commands :lvcreate  => 'lvcreate',
             :lvremove  => 'lvremove',
             :lvextend  => 'lvextend',
             :lvs       => 'lvs',
             :resize2fs => 'resize2fs',
             :umount    => 'umount',
             :mount     => 'mount',
             :dmsetup   => 'dmsetup'

    def create
        args = ['-n', @resource[:name]]
        if @resource[:size]
            args.push('--size', @resource[:size])
        elsif @resource[:initial_size]
            args.push('--size', @resource[:initial_size])
        end
        args << @resource[:volume_group]
        lvcreate(*args)
    end

    def destroy
        dmsetup('remove', "#{@resource[:volume_group]}-#{@resource[:name]}")
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

        resizeable = false
        current_size = size()

        if current_size =~ /(\d+\.{0,1}\d{0,2})(#{lvm_size_units_match})/i
            current_size_bytes = $1.to_i
            current_size_unit  = $2.upcase
        end

        if new_size =~ /(\d+)(#{lvm_size_units_match})/i
            new_size_bytes = $1.to_i
            new_size_unit  = $2.upcase
        end

        ## Get the extend size
        if lvs('--noheading', '-o', 'vg_extent_size', '--units', 'k', path) =~ /\s+(\d+)\.\d+k/i
            vg_extent_size = $1.to_i
        end

        ## Verify that it's a extension: Reduce is potentially dangerous and should be done manually
        if lvm_size_units[current_size_unit] < lvm_size_units[new_size_unit]
            resizeable = true
        elsif lvm_size_units[current_size_unit] > lvm_size_units[new_size_unit]
            if (current_size_bytes / lvm_size_units[current_size_unit]) < (new_size_bytes / lvm_size_units[new_size_unit])
                resizeable = true
            end
        elsif lvm_size_units[current_size_unit] == lvm_size_units[new_size_unit]
            if new_size_bytes > current_size_bytes
                resizeable = true
            end
        end

        if not resizeable
            fail( "Decreasing the size requires manual intervention (#{size} < #{current_size})" )
        else
            ## Check if new size fits the extend blocks
            if new_size_bytes * lvm_size_units[new_size_unit] % vg_extent_size != 0
                fail( "Cannot extend to size #{size} because VG extent size is #{vg_extent_size} KB" )
            end

            lvextend( '-L', new_size, path) || fail( "Cannot extend to size #{size} because lvextend failed." )

            if mount( '-f', '--guess-fstype', path) =~ /ext[34]/
              resize2fs( path) || fail( "Cannot resize file system to size #{size} because resize2fs failed." )
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

end
