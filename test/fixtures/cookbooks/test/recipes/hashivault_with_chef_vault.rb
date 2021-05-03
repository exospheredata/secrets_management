#
# Cookbook:: secrets_management_test
# Recipe:: hashivault_with_chef_vault
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

vault_hash = {}
# By default, the keys need to be symbolized.  The DSL contains a method to convert to symbol
# if a string is passed, so we will test both here.
vault_hash[:token] = node['hashicorp']['token']
vault_hash[:address] = node['hashicorp']['address']

# Test using a ChefVault item to load the hash details.
chef_vault_hash = open_secret_item('secrets', 'token', vault: vault_hash)

vault = Vault::Client.new(vault_hash)
vault.logical.write('/secret/chef/os/secrets_management_test_2', demo: true, test_key: '84')

bag = open_secret_item('/secret/chef/os', 'secrets_management_test_2', bag_type: 'vault', vault: chef_vault_hash)

log 'Test a single hashicorp vault item with ChefVault' do
  message "We found the following details in the test bag: #{bag}"
  level :info
end

file "#{Chef::Config[:file_cache_path]}/hashivault_chef_vault.test" do
  content bag['test_key']
end
