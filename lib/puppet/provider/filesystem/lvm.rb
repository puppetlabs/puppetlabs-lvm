Puppet::Type.type(:filesystem).provide :lvm do
  desc 'Manages filesystem of a logical volume on Linux'

  confine kernel: :linux

  commands blkid: 'blkid'

  def create
    mkfs(@resource[:fs_type], @resource[:name])
  end

  def exists?
    fstype == @resource[:fs_type]
  end

  def destroy
    # no-op
  end

  def fstype
    type_match = %r{\bTYPE=\"(\S+)\"}.match(blkid(@resource[:name]))
    # when creating FS on a non LVM partition that already exists but does not have FS
    # blkid output does not contain `TYPE=....` -> type_match is nil
    if type_match
      type_match[1]
    end
  rescue Puppet::ExecutionFailure
    nil
  end

  def mkfs(fs_type, name)
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

    execute mkfs_cmd
    if fs_type == 'swap'
      swap_cmd = ['swapon']
      swap_cmd << name
      execute swap_cmd
    end
  end
end
