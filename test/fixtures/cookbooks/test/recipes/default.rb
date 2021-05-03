#
# Cookbook:: secrets_management_test
# Recipe:: default
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

include_recipe 'secrets_management_test::hashivault'
include_recipe 'secrets_management_test::chef_vault'
include_recipe 'secrets_management_test::data_bag'
