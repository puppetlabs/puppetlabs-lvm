require 'spec_helper_acceptance'
require 'securerandom'

describe 'create filesystems' do
  describe 'create_filesystem_non-existing-format' do
    let(:pv) do
      '/dev/sdc'
    end
    let(:vg) do
      ('VolumeGroup_' + SecureRandom.hex(2))
    end
    let(:lv) do
      ('LogicalVolume_' + SecureRandom.hex(3))
    end
    let(:pp) do
      <<~MANIFEST
        physical_volume {'#{pv}':
        	ensure  => present,
        }
        ->
        volume_group {'#{vg}':
        	ensure            => present,
        	physical_volumes  => '#{pv}',
        }
        ->
        logical_volume{'#{lv}':
        	ensure        => present,
        	volume_group  => '#{vg}',
        	size          => '20M',
        }
        ->
        filesystem {'Create_filesystem':
        	name    => '/dev/#{vg}/#{lv}',
        	ensure  => present,
        	fs_type => 'non-existing-format',
        }
      			MANIFEST
    end

    it 'applies the manifest' do
      apply_manifest(pp)
      remove_all(pv, vg, lv)
    end
  end

  describe 'create_filesystem_with_ensure_property_ext2' do
    let(:pv) do
      '/dev/sdc'
    end
    let(:vg) do
      ('VolumeGroup_' + SecureRandom.hex(2))
    end
    let(:lv) do
      ('LogicalVolume_' + SecureRandom.hex(3))
    end
    let(:pp) do
      <<~MANIFEST
        physical_volume {'#{pv}':
          ensure  => present,
        }
        ->
        volume_group {'#{vg}':
          ensure            => present,
          physical_volumes  => '#{pv}',
        }
        ->
        logical_volume{'#{lv}':
          ensure        => present,
          volume_group  => '#{vg}',
          size          => '20M',
        }
        ->
        filesystem {'Create_filesystem':
          name    => '/dev/#{vg}/#{lv}',
          ensure  => present,
          fs_type => 'ext2',
        }
      			MANIFEST
    end

    it 'applies the manifest' do
      apply_manifest(pp)
      expect(run_shell("file -sL /dev/#{vg}/#{lv}").stdout).to match %r{ext2}
      remove_all(pv, vg, lv)
    end
  end

  describe 'create_filesystem_with_ensure_property_ext4' do
    let(:pv) do
      '/dev/sdc'
    end
    let(:vg) do
      ('VolumeGroup_' + SecureRandom.hex(2))
    end
    let(:lv) do
      ('LogicalVolume_' + SecureRandom.hex(3))
    end
    let(:pp) do
      <<~MANIFEST
        physical_volume {'#{pv}':
          ensure  => present,
        }
        ->
        volume_group {'#{vg}':
          ensure            => present,
          physical_volumes  => '#{pv}',
        }
        ->
        logical_volume{'#{lv}':
          ensure        => present,
          volume_group  => '#{vg}',
          size          => '20M',
        }
        ->
        filesystem {'Create_filesystem':
          name    => '/dev/#{vg}/#{lv}',
          ensure  => present,
          fs_type => 'ext4',
        }
      			MANIFEST
    end

    it 'applies the manifest' do
      apply_manifest(pp)
      expect(run_shell("file -sL /dev/#{vg}/#{lv}").stdout).to match %r{ext4}
      remove_all(pv, vg, lv)
    end
  end
end
