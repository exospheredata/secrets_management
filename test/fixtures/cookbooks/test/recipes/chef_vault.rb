#
# Cookbook Name:: secrets_management_test
# Recipe:: chef_vault
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

bag = open_secret_item('secrets', 'bacon')

log 'Test a single chef_vault item' do
  message "We found the following details in the test bag: #{bag}"
  level :info
end

bag = open_secret_item('secrets', 'bacon', bag_type: 'chef_vault')

log 'Test a direct check chef_vault item' do
  message "We found the following details in the test bag: #{bag}"
  level :info
end

file "#{Chef::Config[:file_cache_path]}/chef_vault.test" do
  content bag['password']
end
