#
# Cookbook Name:: secrets_management_test
# Recipe:: data_bag
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

# By disabling this attribute, we can override the fallback included
# in the chef-vault cookbook at properly test the data_bag lookup
node.normal['chef-vault']['databag_fallback'] = false

bag = open_secret_item('simple', 'item', bag_type: 'data_bag')

node.normal['chef-vault']['databag_fallback'] = true

log 'Test a direct check data_bag item' do
  message "We found the following details in the test bag: #{bag}"
  level :info
end

file "#{Chef::Config[:file_cache_path]}/data_bag.test" do
  content bag['test_key']
end
