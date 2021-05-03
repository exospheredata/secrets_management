#
# Cookbook:: secrets_management
# Spec:: default_spec
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

require 'spec_helper'

describe 'secrets_management_test::chef_vault' do
  before do
    # Need to perform the following in order to stub out the chef-vault items.
    allow(ChefVault::Item).to(
      receive(:vault?).with('secrets', 'bacon').and_return(true)
    )
    allow(ChefVault::Item)
      .to receive(:load).with('secrets', 'bacon').and_return('id' => 'bacon',
                                                             'password' => 'my_super_secret')
    allow(Chef::DataBag)
      .to receive(:load).with('secrets').and_return('bacon_keys' => {})
  end
  context 'Validate supported installations' do
    platforms = {
      'redhat' => {
        'versions' => %w(7),
      },
      'ubuntu' => {
        'versions' => %w(18.04),
      },
    }
    platforms.each do |platform, components|
      components['versions'].each do |version|
        context "On #{platform} #{version}" do
          context 'When all attributes are default' do
            before do
              Fauxhai.mock(platform: platform, version: version)
            end
            let(:runner) do
              ChefSpec::SoloRunner.new(platform: platform, version: version, file_cache_path: '/tmp/cache')
            end
            let(:node) { runner.node }
            let(:chef_run) { runner.converge(described_recipe) }

            it 'converges successfully' do
              expect { chef_run }.to_not raise_error
              expect(chef_run).to include_recipe('secrets_management_test::chef_vault')
              expect(chef_run).to write_log('Test a single chef_vault item')
              expect(chef_run).to write_log('Test a direct check chef_vault item')
              expect(chef_run).to create_file('/tmp/cache/chef_vault.test').with(content: 'my_super_secret')
            end
          end
        end
      end
    end
  end
end
