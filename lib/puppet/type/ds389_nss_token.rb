Puppet::Type.newtype(:ds389_nss_token) do
  @doc = 'Manages NSS DB token files for a 389-DS instance.'

  ensurable do
    defaultvalues
    defaultto(:present)
  end

  newparam(:name, namevar: true) do
    desc 'Resource name (usually <instance>_nss_token).'
  end

  newparam(:instance_name) do
    desc 'The name of the 389-DS instance.'
    validate do |value|
      raise ArgumentError, 'instance_name must not be empty' if value.strip.empty?
    end
  end

  newparam(:instance_dir) do
    desc 'Directory where the DS389 instance lives.'
    validate do |value|
      unless value.start_with?('/')
        raise ArgumentError, 'instance_dir must be an absolute path'
      end
    end
  end

  newparam(:token) do
    desc 'Optional user-provided token. If absent, pwdfile.txt is used.'
  end

  # This parameter allows the provider to report status back to Puppet,
  # so Puppet knows whether the resource is in sync.
  newproperty(:status) do
    desc 'Internal status to drive provider actions'
    validate do |_|
      true
    end
  end

  # Autorequire the instance directory
  autorequire(:file) do
    [ self[:instance_dir] ]
  end
end
