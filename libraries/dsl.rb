#
# Library:: secrets_management::dsl
#
# maintainer:: Exosphere Data, LLC
# maintainer_email:: chef@exospheredata.com
#
# Copyright:: 2017, Exosphere Data, LLC, All Rights Reserved.

module SecretsManagement
  module DSL
    require 'vault'

    # The 'open_secret_item' method allows us to dynamically handle the opening and error_handling
    # of several types of secrets options.  The method will wrap the individual calls and return
    # exceptions or data depending on the validity of the item's return.
    def open_secret_item(container, item, bag_type: nil, vault: {})
      # If the bag_type key is not set, then we should be able to attempt to figure it out by
      # testing the different available methods.  We will do this first before testing
      # the case statement
      return determine_container_type(container, item, vault: vault) if bag_type.nil?

      Chef::Log.debug("Checking for the secret bag_type #{bag_type}")

      # Since, the 'bag_type' parameter was sent, we will use a case statement to look
      # up the individual type method and return an output.  If an invalid bag_type is sent,
      # We will raise a clearly documented error.
      case bag_type
      when 'vault'
        bag_item = find_hashicorp_vault_item(container, item, vault)
      when 'chef_vault'
        bag_item = find_chef_vault_item(container, item)
      when 'data_bag'
        bag_item = find_data_bag_item(container, item)
      else
        raise ArgumentError, "An invalid secret type (#{bag_type}) has been provided for ('#{container}','#{item}').  Currently, the only supported versions are 'vault', 'chef_vault', and 'data_bag'"
      end

      # If the returned data does not contain and error message, then return the data.  Otherwise,
      # we need to raise a clearly documented exception as an ArgumentError.
      return bag_item unless bag_item.key?(:error)
      raise ArgumentError, bag_item[:error]
    end

    private

    # The 'determine_container_type' method will make multiple calls to each supported bag_type
    # method in the private module methods to find the most appropriate item type.  We are
    # setting the vault parameter to an empty hash by default in the event that the data is empty.
    # This action solves for an empty call and keeps the errors clean.
    def determine_container_type(container, item, vault: {})
      Chef::Log.debug("Attempting to determine the bag type for #{container}")

      # For each type that we test, we should monitor for an exception.  Since we are looking
      # up the type, we will ignore any valid responses with a error message in the output.
      bag_item = find_hashicorp_vault_item(container, item, vault)
      return bag_item unless bag_item.key?(:error)
      raise ArgumentError, bag_item[:error] if bag_item.key?(:error) && container.include?('/')

      unless container.include?('/')
        bag_item = find_chef_vault_item(container, item)
        return bag_item unless bag_item.key?(:error) && bag_item != {}

        # Finally, test to see if this is a basic data bag item
        bag_item = find_data_bag_item(container, item)
        return bag_item unless bag_item.key?(:error)
      end

      raise ArgumentError, "Failure: Unable to determine the bag_type or retrieve the bag_item (\'#{container}\',\'#{item}\').  This item might not exist."
    end

    def find_hashicorp_vault_item(bag, item, vault_hash)
      Chef::Log.debug("Gathering the details for HashicorpVaultItem(\'#{bag}\',\'#{item}\')")

      # To support both string and symbol keys, we will just convert the hash keys by default.
      vault_hash = symbolize_keys(vault_hash)

      # We need to declare this variable as an empty hash to prevent unknown type errors
      # when testing later.  This is due to wrapping the vault calls with retries.
      bag_item = {}
      begin
        # This check is useful when we are trying to determine the bag bag_type.
        return { error: 'You did not provide details for the Hashicorp Vault server.' } if vault_hash.empty? || vault_hash[:token].nil? || vault_hash[:address].nil?
        vault = create_hashicorp_client(vault_hash)

        # If the node attribute ['hashicorp']['refresh_token'] is set or we receive the information
        # in the hash, then we will request that the token be refreshed to a maximum of the value provided.
        # However, this value cannot exceed the configured default token TTL.
        token_refresh = vault_hash['renew_token'] || nil
        token_refresh = node['hashicorp']['refresh_token'] unless node['hashicorp']['refresh_token'].nil?

        Chef::Log.debug("Renewing the Vault token: #{token_refresh}") unless token_refresh.nil?
        vault.auth_token.renew_self token_refresh unless token_refresh.nil?

        vault.with_retries(Vault::HTTPConnectionError, Vault::HTTPError) do |attempt, e|
          log "Received exception #{e} from Vault - attempt #{attempt}" if e
          bag_item = vault.logical.read("#{bag}/#{item}")
        end

        # Since Vault doesn't send an error when the item is not found, we will need to force
        # the system to error out if the variable 'bag_item' is empty or nil.
        raise '404' if bag_item.nil?
      rescue Vault::HTTPConnectionError,
             Vault::HTTPServerError,
             Vault::HTTPClientError => error
        raise error
      rescue StandardError => error
        # Any unexplained error should be thrown immediately.  Otherwise, a 404 should be graceful
        # raise error.inspect
        raise error.message unless error.nil? || error.message == '404'
        bag_item = { error: "This action requires that the HashicorpVaultItem(\'#{bag}/#{item}\') exists and that this system can access it.  We failed to find the required items." }
        return bag_item
      end

      bag_data = {}
      # Return the data from the Vault and not the Vault object
      bag_item.data.each do |k, v|
        bag_data[k.to_s] = v
      end
      bag_data
    end

    def find_chef_vault_item(bag, item)
      Chef::Log.debug("Gathering the details for ChefVaultItem(\'#{bag}\',\'#{item}\')")
      begin
        bag_item = chef_vault_item(bag, item)
        raise if bag_item.nil?
      rescue ChefVault::Exceptions::SecretDecryption => e
        raise ArgumentError, "ChefVault::Exceptions::SecretDecryption: #{e.message}"
      rescue Net::HTTPServerException
        bag_item = { error: "This action requires that the ChefVaultItem(\'#{bag}\',\'#{item}\') exists and that this system can access it.  We failed to find the required item." }
      rescue StandardError
        bag_item = { error: "This action requires that the ChefVaultItem(\'#{bag}\',\'#{item}\') exists and that this system can access it.  We failed to find the required items." }
        return bag_item
      end
      bag_item # Return the data from the bag and not the bag object
    end

    def find_data_bag_item(bag, item)
      Chef::Log.debug("Gathering the details for DataBagItem(\'#{bag}\',\'#{item}\')")
      begin
        bag_item = data_bag_item(bag, item)
        raise if bag_item.nil?
      rescue StandardError
        bag_item = { error: "This action requires that the DataBagItem(\'#{bag}\',\'#{item}\') exists but it was not found." }
        return bag_item
      end
      bag_item # Return the data from the bag and not the bag object
    end

    def create_hashicorp_client(vault_hash)
      # We shouldn't get to this point without the keys as symbols but just in case.
      Vault::Client.new(symbolize_keys(vault_hash))
    end

    def symbolize_keys(hash_var)
      new_hash = {}
      hash_var.each do |k, v|
        new_hash[k.to_sym] = v
      end
      new_hash
    end
  end
end

Chef::Recipe.send(:include, SecretsManagement::DSL)
Chef::Resource.send(:include, SecretsManagement::DSL)
