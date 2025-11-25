# @summary Consolidate selinux_port enable/disable logic
#
# @author https://github.com/simp/pupmod-simp-ds389/graphs/contributors
#
# @param default
#   The default port for this service (to avoid conflicts with other services)
#
# @param instance
#   The instance name (used to create dependencies)
#
# @param enable
#   Whether to enable or disable the selinux port
#
define ds389::instance::selinux::port (
  Stdlib::Port        $default,
  Optional[String[1]] $instance = undef,
  Boolean             $enable   = true
) {
  assert_private()

  $_port = Integer($title)

  if ($_port != $default) and $facts['os']['selinux']['enforced'] {
    $_ensure = $enable ? {
      true  => 'present',
      false => 'absent'
    }

    selinux_port { "tcp_${_port}-${_port}":
      ensure    => $_ensure,
      low_port  => $_port,
      high_port => $_port,
      seltype   => 'ldap_port_t',
      protocol  => 'tcp',
    }

    if $instance {
      Selinux_port["tcp_${_port}-${_port}"] -> Exec["Setup ${instance} DS"]
      Selinux_port["tcp_${_port}-${_port}"] -> Ds389::Instance::Service[$instance]
    }
  }
}
