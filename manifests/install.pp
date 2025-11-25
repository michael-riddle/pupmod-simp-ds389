# @summary Set up a local 389DS server
#
# @param package_list
#   A list of packages that will installed instead of the internally selected
#   packages.
#
# @param dnf_module
#   The name of the dnf module to install for el8 systems
#
# @param dnf_stream
#   The stream of the dnf module to install for el8 systems
#
# @param dnf_enable_only
#   Whether to only enable the dnf module without installing any packages
#
# @param dnf_profile
#   The profile of the dnf module to install for el8 systems
#
# @param setup_command
#   The path to the setup command on the system
#
# @param remove_command
#   The path to the remove command on the system
#
# @param dsconf_command
#   The path to the dsconf command on the system
#
# @author https://github.com/simp/pupmod-simp-ds389/graphs/contributors
#
class ds389::install (
  Optional[Array[String[1]]] $package_list    = undef,
  Optional[String[1]]        $dnf_module      = undef,
  Optional[String[1]]        $dnf_stream      = undef,
  Boolean                    $dnf_enable_only = false,
  Optional[String]           $dnf_profile     = undef,
  Stdlib::Unixpath           $setup_command   = '/usr/sbin/dscreate',
  Stdlib::Unixpath           $remove_command  = '/usr/sbin/dsctl',
  Stdlib::Unixpath           $dsconf_command  = '/usr/sbin/dsconf'
) {
  assert_private()

  unless $package_list or $dnf_module {
    fail('You must specify either "$package_list" or "$dnf_module"')
  }

  if $dnf_module and ( $facts['package_provider'] == 'dnf' ) {
    package { $dnf_module:
      ensure      => $dnf_stream,
      enable_only => $dnf_enable_only,
      flavor      => $dnf_profile,
      provider    => 'dnfmodule',
    }
  }

  if $package_list and !empty($package_list) {
    stdlib::ensure_packages($package_list, { ensure => $ds389::package_ensure })
  }
}
