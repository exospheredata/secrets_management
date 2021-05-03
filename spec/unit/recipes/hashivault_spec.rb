#
# Cookbook:: secrets_management
# Spec:: default_spec
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

require 'spec_helper'

describe 'secrets_management_test::hashivault' do
  before do
    # Hashivault stubs using webmocks
    response_headers = { 'Content-Type' => 'application/json' }
    vault_found = { request_id: '12345', lease_id: '', renewable: false, lease_duration: 2764800, data: { demo: true, test_key: '42' }, wrap_info: nil, warnings: nil, auth: nil }

    stub_request(:get, 'http://192.168.0.1:8200/v1//secret/chef/os/secrets_management_test_1').to_return(status: 200, body: vault_found.to_json, headers: response_headers)
    stub_request(:put, 'http://192.168.0.1:8200/v1//secret/chef/os/secrets_management_test_1').with(body: '{"demo":true,"test_key":"42"}').to_return(status: 204, body: '', headers: response_headers)
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
              expect { chef_run }.to_not raise_error
              expect(chef_run).to include_recipe('secrets_management_test::hashivault')
              expect(chef_run).to write_log('Test a single hashicorp vault item')
              expect(chef_run).to create_file('/tmp/cache/hashivault.test').with(content: '42')
            end

            it 'raises an error if no token' do
              node.normal['hashicorp']['token'] = nil
              expect { chef_run }.to raise_error(ArgumentError, 'You did not provide details for the Hashicorp Vault server.')
            end

            it 'raises an Vault::HTTPClientError exception when permission denied' do
              stub_request(:get, 'http://192.168.0.1:8200/v1//secret/chef/os/secrets_management_test_1').to_return(status: 403, body: 'permission denied', headers: { 'Content-Type' => 'application/json' })
              expect { chef_run }.to raise_error(Vault::HTTPClientError, /permission denied/)
            end

            it 'raises an Vault::HTTPServerError exception when server not responding' do
              stub_request(:get, 'http://192.168.0.1:8200/v1//secret/chef/os/secrets_management_test_1').to_return(status: 503, body: 'connection refused: 192.168.100.78:8200', headers: { 'Content-Type' => 'application/json' })
              expect { chef_run }.to raise_error(Vault::HTTPServerError, /connection refused/)
            end
          end
        end
      end
    end
  end
end
