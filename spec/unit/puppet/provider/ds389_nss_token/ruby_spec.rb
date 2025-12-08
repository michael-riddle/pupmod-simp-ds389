# frozen_string_literal: true

require 'spec_helper'
require 'puppet'
# require 'puppet/type/ds389_nss_token'
# require_relative '../../../../../lib/puppet/provider/ds389_nss_token/ruby'

provider_class = Puppet::Type.type(:ds389_nss_token).provider(:ruby)
describe provider_class do
  let(:instance_dir) { '/tmp/slapd-test' }
  let(:token_path) { File.join(instance_dir, 'token.txt') }
  let(:pin_path) { File.join(instance_dir, 'pin.txt') }
  let(:pwdfile) { File.join(instance_dir, 'pwdfile.txt') }

  let(:resource) do
    Puppet::Type.type(:ds389_nss_token).new(
      name: 'test_instance_nss_token',
      instance_name: 'test_instance',
      instance_dir: instance_dir,
    )
  end

  let(:provider) { provider_class.new(resource) }

  before(:each) do
    FileUtils.mkdir_p(instance_dir)
    File.write(pwdfile, "defaultpw\n")
  end

  after(:each) do
    FileUtils.rm_rf(instance_dir)
  end

  describe '#exists?' do
    it 'returns false when token file is missing' do
      expect(provider.exists?).to be false
    end

    it 'returns true when token file exists' do
      File.write(token_path, 'abc')
      expect(provider.exists?).to be true
    end
  end

  describe '#desired_token' do
    it 'uses user token if supplied' do
      resource[:token] = 'usertoken'
      expect(provider.desired_token).to eq('usertoken')
    end

    it 'falls back to pwdfile.txt when no user token' do
      expect(provider.desired_token).to eq('defaultpw')
    end
  end

  describe '#create' do
    it 'creates token.txt and pin.txt' do
      provider.create
      expect(File.read(token_path).strip).to eq('defaultpw')
      expect(File.read(pin_path).strip).to eq('Internal (Software) Token:defaultpw')
    end

    it 'backs up old token file' do
      File.write(token_path, 'oldvalue')
      provider.create
      expect(File.exist?(File.join(instance_dir, 'token.txt.previous_token'))).to be false
    end

    it 'raises error if instance_dir missing' do
      resource[:instance_dir] = '/no/such/path'
      expect { provider.create }.to raise_error(Puppet::Error)
    end
  end

  describe '#destroy' do
    it 'removes token and pin files' do
      File.write(token_path, 'x')
      File.write(pin_path, 'x')
      provider.destroy
      expect(File.exist?(token_path)).to be false
      expect(File.exist?(pin_path)).to be false
    end
  end
end
