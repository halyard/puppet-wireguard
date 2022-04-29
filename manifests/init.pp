# @summary Configure wireguard networks
#
# @param networks sets the list of WG networks to create
class wireguard (
  Hash[String, Hash[String, Any]] $networks = {},
) {
  package { 'wireguard-tools': }

  -> file { [
      '/etc/wireguard/private',
      '/etc/wireguard/public',
      '/etc/wireguard/peers',
  ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  $networks.each |String $interface, Hash $peers| {
    wireguard::network { $interface:
      peers => $peers,
    }
  ]
}
