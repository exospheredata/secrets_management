#
# Cookbook Name:: secrets_management_test
# Recipe:: hashivault
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

vault_hash = {}
# By default, the keys need to be symbolized.  The DSL contains a method to convert to symbol
# if a string is passed, so we will test both here.
vault_hash[:token] = node['hashicorp']['token']
vault_hash[:address] = node['hashicorp']['address']

vault = Vault::Client.new(vault_hash)
vault.logical.write('/secret/chef/os/secrets_management_test_1', demo: true, test_key: '42')

bag = open_secret_item('/secret/chef/os', 'secrets_management_test_1', vault: vault_hash)

log 'Test a single hashicorp vault item' do
  message "We found the following details in the test bag: #{bag}"
  level :info
end

file "#{Chef::Config[:file_cache_path]}/hashivault.test" do
  content bag['test_key']
end
