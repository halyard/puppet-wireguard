# @summary Configure wireguard networks
#
# @param networks sets the list of WG networks to create
# @param routers is an optional list of subnets that the instance should route for
class wireguard (
  Hash[String, Hash[String, Any]] $networks = {},
  Array[String] $routers = [],
) {
  package { 'wireguard-tools': }

  -> file { [
      '/etc/wireguard/private',
      '/etc/wireguard/public',
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
  }

  if length($routers) > 0 {
    file { '/etc/sysctl.d/wireguard.conf':
      ensure  => file,
      content => 'net.ipv4.ip_forward=1',
    }

    ~> service { 'systemd-sysctl':
      ensure => running,
      enable => true,
    }

    $routers.each |String $router| {
      firewall { "100 masquerade for wireguard routing on ${router}":
        chain  => 'POSTROUTING',
        action => 'MASQUERADE',
        source => $router,
        table  => 'nat',
      }
      firewall { "100 forward for wireguard routing on ${router}":
        chain  => 'FORWARD',
        action => 'ACCEPT',
        source => $router,
      }
    }
  }
}
