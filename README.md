# secrets_management
### _A Chef library for global secrets management_

This cookbook provides a Ruby library helper to support management of Hashicorp Vault, Chef Vault, and Chef DataBag items.  This cookbook does not include resources or recipes.  The purpose of this project is to simplify the handling of secrets and data management by integrating a single method whereby Hashicorp Vault, Chef Vault, and Chef DataBag items can be managed.

**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Requirements](#requirements)
  - [Platforms](#platforms)
  - [Chef](#chef)
  - [Cookbooks](#cookbooks)
- [Usage](#usage)
  - [default](#default)
- [Libraries](#libraries)
  - [SecretsManagement::DSL](#secretsmanagementdsl)
- [Upload to Chef Server](#upload-to-chef-server)
- [Upload to Private Chef Supermarket](#upload-to-private-chef-supermarket)
- [Cookbook Testing](#cookbook-testing)
  - [Before you begin](#before-you-begin)
  - [Data_bags for Test-Kitchen](#data_bags-for-test-kitchen)
  - [Rakefile and Tasks](#rakefile-and-tasks)
  - [Chefspec and Test-Kitchen](#chefspec-and-test-kitchen)
  - [Test Cookbook (secrets_management_test)](#test-cookbook-secrets_management_test)
  - [Compliance Profile](#compliance-profile)
- [Contribute](#contribute)
- [License & Authors](#license-&-authors)

## Requirements

### Platforms

This resource should work on any Chef supported platform with a Chef Client meeting the minimum requirements.

### Chef

- 12.5+

### Cookbooks

- chef-vault, '~> 3.0'

## Usage
To use the libraries, declare a dependency on this cookbook, and then use the libary as described in the section [SecretsManagement::DSL](#secretsmanagementdsl).

### default

This is an empty recipe and should _not_ be modified.

## Libraries

### SecretsManagement::DSL

#### open_secret_item
The `open_secret_item` method supports accessing existing Hashicorp Vault, Chef Vault, and Chef DataBag items.  The method supports two possible models for getting the data - `determine_bag_type` or `find_<type>_item`.  By default, the method will attempt to perform the lookup unless the attribute `:type` is sent.

Properties:

| Name          | Description | Type  | Mandatory |
| ---           | ---         | ---   | ---       |
| **container** | Path to Hashicorp Vault or the Name of the Chef Vault or DataBag | String | X |
| **item**      | Item name in Vault or Bag | String | X |
| type          | Supported values: `vault` (Hashicorp), `chef_vault`, or `data_bag` | String |           |
| vault         | Hash of supported keys for accessing Hashicorp environment.  Minimum required keys are `address` and `token`. | Hash   |           |

_Note: When returning details from Hashicorp Vault, this library will normalize the key names as strings.  By default, the keys will be returned as a symbol.  To keep this output consistent across the ChefVault and DataBag models, the library converts the keys from symbols to strings._

#### Examples

```ruby
# Open a secret item based on testing the options - vault, chef_vault, then data_bag
bag = open_secret_item('secret', 'item')

# Include a vault object to support looking into Hashicorp as part of the lookup
bag = open_secret_item('secret', 'item', vault: { 'token' => '1234', 'address' => 'http://192.168.0.1:8200' })
```

```ruby
# Look up a data_bag item
bag = open_secret_item('simple', 'item', type: 'data_bag')
```

```ruby
# Lookup a chef_vault item
bag = open_secret_item('secrets', 'bacon', type: 'chef_vault')
```

```ruby
# Lookup a chef_vault item and use the output to access a Hashicorp Vault item
vault_hash = open_secret_item('vault', 'secret', type: 'chef_vault')
bag = open_secret_item('secret/chef/os', 'windows', type: 'vault', vault: vault_hash)
```

## Upload to Chef Server
This cookbook should be included in each organization of your CHEF environment.  When importing, leverage Berkshelf:

`berks upload --except test`

_NOTE:_ use the --no-ssl-verify switch if the CHEF server in question has a self-signed SSL certificate.

`berks upload --no-ssl-verify --except test`

## Upload to Private Chef Supermarket
_NOTE:_ You must set the following key `knife[:supermarket_site] = 'https://<your-supermarket-server>'`.

This cookbook should be uploaded to the CHEF Supermarket server.  When importing, leverage Berkshelf vendor command:

```bash
# From a Linux/Mac host via Bash
berks vendor .bundle
for i in `ls .bundle`; do knife cookbook site share $i "Other" -o .bundle; done
```
or
```powershell
# From a Windows host via PowerShell
berks vendor .bundle
foreach ($i in (Get-ChildItem -Path .bundle) ){
  knife cookbook site share $i "Other" -o .bundle
}
```

## Cookbook Testing

### Before you begin
Setup your testing and ensure all dependencies are installed.  Open a terminal windows and execute:

```ruby
gem install bundler
bundle install
berks install
```

### Data_bags for Test-Kitchen

This cookbook requires the use of a data_bag for setting certain values.  Local JSON version need to be stored in the directory structure as indicated below:

```
├── chef-repo/
│   ├── cookbooks
│   │   ├── secrets_management
│   │   │   ├── .kitchen.yml
│   │   │   ├── test
│   │   │   │   ├── fixtures
│   │   │   │   │   ├── data_bags
│   │   │   │   │   │   ├── data_bag_name
│   │   │   │   │   │   │   ├── data_bag_item.json

```

**Note**: Storing local testing versions of the data_bags at the root of your repo is considered best practice.  This ensures that you only need to maintain a single copy while protecting the cookbook from being accientally committed with the data_bag.  However, since this cookbook contains no recipes, we have included the test data_bags for Kitchen purposes.  If you must change this location, then update the following key in the .kitchen.yml file.

```
data_bags_path: "test/fixtures/data_bags/"
```

### Rakefile and Tasks
This repo includes a **Rakefile** for common tasks

| Task Command | Description |
| ------------- |-------------|
| **rake** | Run Style, Foodcritic, Maintainers, and Unit Tests |
| **rake style** | Run all style checks |
| **rake style:chef** | Run Chef style checks |
| **rake style:ruby** | Run Ruby style checks |
| **rake style:ruby:auto_correct** | Auto-correct RuboCop offenses |
| **rake unit** | Run ChefSpec examples |
| **rake integration** | Run all kitchen suites |
| **rake maintainers:generate** | Generate MarkDown version of MAINTAINERS file |

### Chefspec and Test-Kitchen

1. `bundle install`: Installs and pulls all ruby gems dependencies from the Gemfile.

2. `berks install`: Installs all cookbook dependencies based on the [Berksfile](Berksfile) and the [metadata.rb](metadata.rb)

3. `rake`: This will run all of the local tests - syntax, lint, unit, and maintainers file.
4. `rake integration`: This will run all of the kitchen tests

### Test Cookbook (secrets_management_test)
_a test cookbook for the available LWRPs_

The cookbook secrets_management does not include any executable recipes as it is designed to be an utility cookbook and support other initiatives.  For the purposes of testing and validating this code, we have included a test cookbook with pre-configured recipes.

| **Name** | **Description** |
| ------------- |-------------|
| _Default_ | Roll-up recipe to test all of the functionality of the LWRP-specific recipes |
| _hashivault_ | Test gathering secrets from Hashicorp Vault environments. |
| _chef_vault_ | Test gathering secrets from ChefVault bags |
| _data_bag_ | Test gathering secrets from Chef DataBags |


### Compliance Profile
Not included as this is a Resource only cookbook with no included recipes.

## Contribute
 - Fork it
 - Create your feature branch (git checkout -b my-new-feature)
 - Commit your changes (git commit -am 'Add some feature')
 - Push to the branch (git push origin my-new-feature)
 - Create new Pull Request

## License & Authors

**Author:** Jeremy Goodrum ([jeremy@exospheredata.com](mailto:jeremy@exospheredata.com))

**Copyright:** 2017 Exosphere Data, LLC

```text
Copyright 2017 Exosphere Data, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```
