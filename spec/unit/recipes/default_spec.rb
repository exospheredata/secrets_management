#
# Cookbook:: secrets_management
# Spec:: default_spec
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

require 'spec_helper'

describe 'secrets_management::default' do
  context 'Install prequisite components' do
    platforms = {
      'ubuntu' => {
        'versions' => %w(14.04 16.04)
      },
      'debian' => {
        'versions' => %w(7.8)
      },
      'centos' => {
        'versions' => %w(7.1.1503 7.2.1511)
      },
      'redhat' => {
        'versions' => %w(7.1 7.2)
      }
    }

    platforms.each do |platform, components|
      components['versions'].each do |version|
        context "On #{platform} #{version}" do
          before do
            Fauxhai.mock(platform: platform, version: version)
          end

          let(:chef_run) { ChefSpec::SoloRunner.new(platform: platform, version: version).converge(described_recipe) }

          it 'converges successfully' do
            expect { chef_run }.to_not raise_error
          end
        end
      end
    end
  end
end