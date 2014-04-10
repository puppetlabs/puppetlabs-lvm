require 'spec_helper'

describe 'lvm', :type => :class do

  describe 'with no parameters' do
    it { should compile.with_all_deps }
  end

  describe 'with volume groups' do
    let(:params) do
      {
        :volume_groups => {
          'myvg' => {
            'physical_volumes' => [ '/dev/sda2', '/dev/sda3', ],
            'logical_volumes'  => {
              'opt'    => {'size' => '20G'},
              'tmp'    => {'size' => '1G' },
              'usr'    => {'size' => '3G' },
              'var'    => {'size' => '15G'},
              'home'   => {'size' => '5G' },
              'backup' => {
                'size'              => '5G',
                'mountpath'         => '/var/backups',
                'mountpath_require' => true
              }
            }
          }
        }
      }
    end

    it { should contain_physical_volume('/dev/sda2') }
    it { should contain_physical_volume('/dev/sda3') }
    it { should contain_volume_group('myvg').with({
      :ensure           => 'present',
      :physical_volumes => [ '/dev/sda2', '/dev/sda3', ]
    }) }

    it { should contain_logical_volume('opt').with( {
      :volume_group => 'myvg',
      :size         => '20G'
    }) }
    it { should contain_filesystem('/dev/myvg/opt') }
    it { should contain_mount('/opt') }

    it { should contain_logical_volume('backup').with({
      :volume_group => 'myvg',
      :size         => '5G'
    }) }
    it { should contain_filesystem('/dev/myvg/backup') }
    it { should contain_mount('/var/backups') }
  end

end
