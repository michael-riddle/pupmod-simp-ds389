# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:ds389_nss_token) do
  let(:resource) do
    described_class.new(
      name: 'test_instance_nss_token',
      instance_name: 'test_instance',
      instance_dir: '/etc/dirsrv/slapd-test_instance',
    )
  end

  context 'attribute :name' do
    it 'is the namevar' do
      expect(described_class.key_attributes).to eq([:name])
    end
  end

  context 'parameter :instance_name' do
    it 'accepts a valid value' do
      resource[:instance_name] = 'ldap01'
      expect(resource[:instance_name]).to eq('ldap01')
    end

    it 'rejects an empty value' do
      expect {
        described_class.new(
          name: 'bad',
          instance_name: '',
          instance_dir: '/tmp'
        )
      }.to raise_error(Puppet::ResourceError, /must not be empty/)
    end
  end

  context 'parameter :instance_dir' do
    it 'accepts an absolute path' do
      resource[:instance_dir] = '/opt/slapd'
      expect(resource[:instance_dir]).to eq('/opt/slapd')
    end

    it 'rejects a relative path' do
      expect {
        described_class.new(
          name: 'bad',
          instance_name: 'x',
          instance_dir: 'not_absolute'
        )
      }.to raise_error(Puppet::ResourceError, /must be an absolute path/)
    end
  end

  context 'property :status' do
    it 'allows any value (no validation)' do
      resource[:status] = 'in_sync'
      expect(resource[:status]).to eq('in_sync')
    end
  end

  context 'autorequires' do
    it 'autorequires the instance directory' do
      file_resource = Puppet::Type::File.new(path: resource[:instance_dir])
      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource file_resource
      catalog.add_resource resource

      expect(resource.autorequire.map(&:source)).to include(file_resource)
    end
  end
end
