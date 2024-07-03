# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'securerandom'

describe 'create filesystems' do
  let(:device_name) do
    (os[:arch] == 'aarch64') ? 'nvme0n3' : 'sdc'
  end

  describe 'create_filesystem_non-existing-format' do
    let(:pv) do
      "/dev/#{device_name}"
    end
    let(:vg) do
      'VolumeGroup'
    end
    let(:lv) do
      'LogicalVolume'
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
      "/dev/#{device_name}"
    end
    let(:vg) do
      'VolumeGroup_ext2'
    end
    let(:lv) do
      'LogicalVolume_ext2'
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
      "/dev/#{device_name}"
    end
    let(:vg) do
      'VolumeGroup_ext4'
    end
    let(:lv) do
      'LogicalVolume_ext4'
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

  describe 'logical_volume_stripes_change_test' do
    let(:pv) { "/dev/#{device_name}" }
    let(:vg) { 'VolumeGroup' }
    let(:lv) { 'LogicalVolume' }

    context 'creating a logical volume' do
      let(:initial_manifest) do
        <<~MANIFEST
          physical_volume { '#{pv}':
            ensure => present,
          }

          volume_group { '#{vg}':
            ensure           => present,
            physical_volumes => '#{pv}',
          }

          logical_volume { '#{lv}':
            ensure       => present,
            volume_group => '#{vg}',
            size         => '20M',
          }
        MANIFEST
      end

      let(:updated_manifest) do
        <<~MANIFEST
          logical_volume { '#{lv}':
            ensure       => present,
            volume_group => '#{vg}',
            size         => '20M',
            stripes      => '2',
          }
        MANIFEST
      end

      it 'creates a logical volume with default stripes' do
        apply_manifest(initial_manifest)
        expect(run_shell("lvs #{vg}/#{lv} --noheadings -o stripes").chomp).to eq('1')
      end

      it 'updates the logical volume with specified stripes' do
        apply_manifest(initial_manifest)
        apply_manifest(updated_manifest)
        expect(run_shell("lvs #{vg}/#{lv} --noheadings -o stripes").chomp).to eq('2')
        remove_all(pv, vg, lv)
      end
    end
  end
end
