# encoding: utf-8
# copyright: 2015, The Authors

title 'Validate Output from Secrets Management'

control 'Verify all files created' do
  impact 1.0
  title 'Verify yum package package @ is installed'
  desc 'Check to see if the host properly installed the yum package '

  describe file('/tmp/kitchen/cache/data_bag.test') do
    it { should be_file }
    its('content') { should eq 'value1' }
  end

  describe file('/tmp/kitchen/cache/chef_vault.test') do
    it { should be_file }
    its('content') { should eq 'my_secret_token' }
  end

  describe file('/tmp/kitchen/cache/hashivault.test') do
    it { should be_file }
    its('content') { should eq '42' }
  end
end
