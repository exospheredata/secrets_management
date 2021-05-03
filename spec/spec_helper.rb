require 'chefspec'
require 'chefspec/berkshelf'
require 'webmock/rspec'
require 'vault'
require 'chef-vault'

WebMock.disable_net_connect!(allow_localhost: true, allow: 'supermarket.chef.io')
