name 'secrets_management'
maintainer 'Exosphere Data, LLC'
maintainer_email 'chef@exospheredata.com'
license 'MIT'
description 'A resource provider for global secrets management'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.0.0'
chef_version '>= 12.5' if respond_to?(:chef_version)

%w(debian ubuntu centos redhat amazon windows).each do |os|
  supports os
end

# Required for integratin with Chef-Vault
depends 'chef-vault', '~> 3.0'

# Required for integration with Hashicorp Vault
gem 'vault', '~> 0.1'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
issues_url 'https://github.com/exospheredata/secrets_management/issues' if respond_to?(:issues_url)

# The `source_url` points to the development reposiory for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
source_url 'https://github.com/exospheredata/secrets_management' if respond_to?(:source_url)
