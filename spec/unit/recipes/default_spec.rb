#
# Cookbook:: secrets_management
# Spec:: default_spec
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

require 'spec_helper'

describe 'secrets_management_test::default' do
  before do
    # Hashivault stubs using webmocks
    response_headers = { 'Content-Type' => 'application/json' }
    vault_found = { request_id: '12345', lease_id: '', renewable: false, lease_duration: 2764800, data: { demo: true, test_key: '42' }, wrap_info: nil, warnings: nil, auth: nil }

    stub_request(:get, 'http://192.168.0.1:8200/v1//secret/chef/os/secrets_management_test_1').to_return(status: 200, body: vault_found.to_json, headers: response_headers)
    stub_request(:put, 'http://192.168.0.1:8200/v1//secret/chef/os/secrets_management_test_1').with(body: '{"demo":true,"test_key":"42"}').to_return(status: 204, body: '', headers: response_headers)

    vault_found = { request_id: '12345', lease_id: '', renewable: false, lease_duration: 2764800, data: { demo: true, test_key: '84' }, wrap_info: nil, warnings: nil, auth: nil }

    stub_request(:get, 'http://192.168.0.1:8200/v1//secret/chef/os/secrets_management_test_2').to_return(status: 200, body: vault_found.to_json, headers: response_headers)
    stub_request(:put, 'http://192.168.0.1:8200/v1//secret/chef/os/secrets_management_test_2').with(body: '{"demo":true,"test_key":"84"}').to_return(status: 204, body: '', headers: response_headers)

    # Need to perform the following in order to stub out the chef-vault items.
    allow(ChefVault::Item).to(
      receive(:vault?).with('secrets', 'bacon').and_return(true)
    )
    allow(ChefVault::Item)
      .to receive(:load).with('secrets', 'bacon').and_return('id' => 'bacon',
                                                             'password' => 'my_super_secret')
    allow(Chef::DataBag)
      .to receive(:load).with('secrets').and_return('bacon_keys' => {})

    stub_data_bag_item('simple', 'item').and_return(
      'test_key' => 'value1'
    )

    stub_request(:get, 'http://192.168.0.1:8200/v1/secrets/token').to_return(status: 404, body: {}.to_json, headers: response_headers)
    allow(ChefVault::Item).to(
      receive(:vault?).with('secrets', 'token').and_return(true)
    )
    allow(ChefVault::Item)
      .to receive(:load).with('secrets', 'token').and_return('id' => 'token',
                                                             'token' => 'my_super_secret',
                                                             'address' => 'http://192.168.0.1:8200')
    allow(Chef::DataBag)
      .to receive(:load).with('secrets').and_return('token_keys' => {})
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
              node.normal['hashicorp']['bag_item'] = 'windows'
              node.normal['hashicorp']['token'] = '123456789'
              node.normal['hashicorp']['address'] = 'http://192.168.0.1:8200'
            end
            let(:runner) do
              ChefSpec::SoloRunner.new(platform: platform, version: version, file_cache_path: '/tmp/cache')
            end
            let(:node) { runner.node }
            let(:chef_run) { runner.converge(described_recipe) }

            it 'converges successfully' do
              expect(chef_run).to include_recipe('secrets_management_test::hashivault')
              expect(chef_run).to include_recipe('secrets_management_test::chef_vault')
              expect(chef_run).to include_recipe('secrets_management_test::data_bag')
              expect { chef_run }.to_not raise_error
            end
          end
        end
      end
    end
  end
end
