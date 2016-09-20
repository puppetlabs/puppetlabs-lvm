require 'spec_helper'

describe 'lvm::profile', :type => :define do

  context "when declared" do
    let (:title) { 'dockerpool' }
    let(:params) {{
      :volume => 'dockerpool',
      :group  => 'data',
      :allocation => {
        'thin_pool_zero' => 1,
      },
      :activation => {
        'thin_pool_autoextend_threshold' => '80',
        'thin_pool_autoextend_percent'   => '20',
      }
    }}

    it do
      is_expected.to contain_file('/etc/lvm/profile/dockerpool.profile').with(
        :ensure => :file,
        :content => "# Managed by Puppet\n#\nallocation {\n  thin_pool_zero=1\n}\nactivation {\n  thin_pool_autoextend_threshold=80\n  thin_pool_autoextend_percent=20\n}\n"
      )
    end

    it do
      is_expected.to contain_exec('lvm::profile::lvchange').with(
        :command => 'lvchange --profile dockerpool data/dockerpool',
        :refreshonly => true
      ).that_subscribes_to('File[/etc/lvm/profile/dockerpool.profile]')
    end

  end
end
