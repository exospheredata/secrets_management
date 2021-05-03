name 'secrets_management'
maintainer 'Exosphere Data, LLC'
maintainer_email 'chef@exospheredata.com'
license 'MIT'
description 'A resource provider for global secrets management'
version '1.0.0'
chef_version '>= 16.0' # 16.0+ includes Chef-Vault out of the box

%w(debian ubuntu centos redhat amazon windows).each do |os|
  supports os
end

# Required for integration with Hashicorp Vault
gem 'vault', '~> 0.1'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
issues_url 'https://github.com/exospheredata/secrets_management/issues'

# The `source_url` points to the development reposiory for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
source_url 'https://github.com/exospheredata/secrets_management'
