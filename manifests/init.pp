# @summary Configure wireguard networks
#
# @param networks sets the list of WG networks to create
# @param routers is an optional list of subnets that the instance should route for
# @param alternate_ports sets the extra ports that can be used for wireguard clients
class wireguard (
  Hash[String, Hash[String, Any]] $networks = {},
  Array[String] $routers = [],
  Array[Integer] $alternate_ports = [],
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

  firewall { '100 allow inbound wireguard traffic':
    dport  => 41194,
    proto  => 'udp',
    action => 'accept',
  }

  $alternate_ports.each |Integer $port| {
    firewall { "100 redirect ${port} as alternate wireguard port":
      table    => 'nat',
      chain    => 'PREROUTING',
      dst_type => 'LOCAL',
      proto    => 'udp',
      dport    => $port,
      action   => 'redirect',
      to_ports => 41194,
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
        jump   => 'MASQUERADE',
        proto  => 'all',
        source => $router,
        table  => 'nat',
      }
      firewall { "100 forward for wireguard routing on ${router}":
        chain  => 'FORWARD',
        proto  => 'all',
        action => 'accept',
        source => $router,
      }
    }
  }
}
