#
# Cookbook:: secrets_management
# Spec:: default_spec
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

require 'spec_helper'

describe 'secrets_management_test::data_bag' do
  before do
    stub_data_bag_item('simple', 'item').and_return(
      'test_key' => 'value1'
    )
  end
  context 'Validate supported installations' do
    platforms = {
      'redhat' => {
        'versions' => %w(7.3),
      },
      'ubuntu' => {
        'versions' => %w(16.04),
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
              expect(chef_run).to include_recipe('secrets_management_test::data_bag')
              expect(chef_run).to write_log('Test a direct check data_bag item')
              expect(chef_run).to create_file('/tmp/cache/data_bag.test').with(content: 'value1')
            end
          end
        end
      end
    end
  end
end
