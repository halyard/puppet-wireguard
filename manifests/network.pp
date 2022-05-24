# @summary Configure wireguard network
#
# @param peers sets the peers for the network
# @param network sets the name of the network
define wireguard::network (
  Hash[String, Hash] $peers = {},
  String $network = $title,
) {
  $self_name = $configvault::user
  $self = $peers[$self_name]
  unless $self {
    fail("Own WG peer not defined: ${self_name}")
  }

  $privkey_file = "/etc/wireguard/private/${network}"
  $pubkey_file = "/etc/wireguard/public/${network}"

  exec { "Create private key for ${network}":
    command => "/usr/bin/wg genkey > ${privkey_file}",
    creates => $privkey_file,
    require => [
      File['/etc/wireguard/private'],
      Package['wireguard-tools'],
    ],
  }

  -> exec { "Create public key for ${network}":
    command => "/usr/bin/wg pubkey < ${privkey_file} > ${pubkey_file}",
    creates => $pubkey_file,
    require => File['/etc/wireguard/public'],
  }

  -> Configvault_Write { "wireguard/${network}.key":
    source => $privkey_file,
  }

  -> Configvault_Write { "wireguard/${network}.pub":
    source => $pubkey_file,
    public => true,
  }

  -> file { "/etc/wireguard/${network}.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('wireguard/network.conf.erb'),
  }

  ~> service { "wg-quick@${network}":
    ensure => running,
    enable => true,
  }
}
