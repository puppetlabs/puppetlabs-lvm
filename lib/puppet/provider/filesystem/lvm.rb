Puppet::Type.type(:filesystem).provide :lvm do
  desc 'Manages filesystem of a logical volume on Linux'

  confine kernel: :linux

  commands blkid: 'blkid', findmnt: 'findmnt', umount: 'umount'

  def create
    mkfs(@resource[:fs_type], @resource[:name], @resource[:force])
  end

  def exists?
    fstype(@resource[:name]) == @resource[:fs_type]
  end

  def destroy
    # no-op
  end

  def fstype(name)
    %r{\bTYPE=\"(\S+)\"}.match(blkid(name))[1]
  rescue Puppet::ExecutionFailure
    nil
  end

  def mounted(name)
    findmnt('-rno', 'SOURCE', name)
  rescue Puppet::ExecutionFailure
    false
  end

  def mkfs(fs_type, name, force)
    mkfs_params = { 'reiserfs' => '-q', 'xfs' => '-f' }

    mkfs_cmd = !@resource[:mkfs_cmd].nil? ?
                 [@resource[:mkfs_cmd]] :
               case fs_type
               when 'swap'
                 ['mkswap']
               else
                 ["mkfs.#{fs_type}"]
               end

    mkfs_cmd << name

    if mkfs_params[fs_type]
      mkfs_cmd << mkfs_params[fs_type]
    end

    if resource[:options]
      mkfs_options = Array.new(resource[:options].split)
      mkfs_cmd << mkfs_options
    end

    current_fs_type = fstype(name)
    unless current_fs_type.nil?
      if force == :true || force == true || force == 'true'
        umount(name) if mounted(name)
        info("#{name} will be umount and FS will be changed to #{fs_type} (currently #{current_fs_type})")
      else
        raise(Puppet::Error, "Changing FS type is destructive operation and it requires manual intervention (from #{current_fs_type} to #{fs_type}) or set force argument.")
      end
    end

    execute mkfs_cmd
    if fs_type == 'swap'
      swap_cmd = ['swapon']
      swap_cmd << name
      execute swap_cmd
    end
  end
end
