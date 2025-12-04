Puppet::Type.type(:ds389_nss_token).provide(:ruby) do
  commands modutil: '/usr/bin/modutil'

  def token_file
    File.join(resource[:instance_dir], 'token.txt')
  end

  def previous_token_file
    File.join(resource[:instance_dir], 'token.txt.previous_token')
  end

  def pin_file
    File.join(resource[:instance_dir], 'pin.txt')
  end

  def pwdfile
    File.join(resource[:instance_dir], 'pwdfile.txt')
  end

  #
  # Does the resource already exist?
  #
  def exists?
    File.exist?(token_file)
  end

  #
  # Provider MUST return something for the property so Puppet can decide
  # whether to call create.
  #
  def status
    existing = File.exist?(token_file) ? File.read(token_file).strip : nil
    expected = desired_token
    (existing == expected) ? 'in_sync' : 'out_of_sync'
  end

  def status=(_value)
    create
  end

  #
  # Determine desired token (user or default)
  #
  def desired_token
    user_defined = resource[:token]
    return user_defined if user_defined && !user_defined.strip.empty?
    File.read(pwdfile).strip
  end

  #
  # Create or update token files
  #
  def create
    dir = resource[:instance_dir]
    unless Dir.exist?(dir)
      raise Puppet::Error, "Instance directory #{dir} not found"
    end

    first_run = !File.exist?(token_file)
    current_default = File.read(pwdfile).strip
    desired = desired_token

    # Backup the old token file if it exists
    if File.exist?(token_file)
      File.write(previous_token_file, File.read(token_file))
    end

    # Write token.txt
    File.write(token_file, desired)

    # Write pin.txt
    File.write(pin_file, "Internal (Software) Token:#{desired}\n")

    # If desired matches the default, no need to change the token
    if desired != current_default
      previous_pw_source =
        if first_run && resource[:token] && resource[:token] != current_default
          pwdfile
        else
          previous_token_file
        end

      modutil(
        '-dbdir', dir,
        '-changepw', 'NSS Certificate DB',
        '-pwfile', previous_pw_source,
        '-newpwfile', token_file,
        '-force'
      )
    end

    # Clean up backup if not needed anymore
    return unless File.exist?(previous_token_file)
    File.delete(previous_token_file)
  end

  def destroy
    File.delete(token_file) if File.exist?(token_file)
    File.delete(pin_file) if File.exist?(pin_file)
  end
end
