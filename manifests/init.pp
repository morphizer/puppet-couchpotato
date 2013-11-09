# == Class: couchpotato
#
# Installs and configures couchpotato.
#
# === Parameters
#
# [*install_dir*]
#   Where couchpotato should be installed to. Default: /opt/couchpotato
#
# [*user*]
#   The user to run the couchpotato service as. Default: couchpotato
#
# [*address*]
#   Address to listen on. Default: 0.0.0.0
#
# [*port*]
#   Port to listen on. Default: 8082
#
# === Examples
#
# include couchpotato
#
# === Authors
#
# Andrew Harley <morphizer@gmail.com>
#
class couchpotato (
  $install_dir = '/opt/couchpotato',
  $user = 'couchpotato',
  $address = '0.0.0.0',
  $port = '8082',
) {

  # Install required  dependencies
  $dependencies = [ 'python', 'git' ]

  package { $dependencies:
    ensure => installed,
  }

  # Create a user to run couchpotato as
  user { $user:
    ensure     => present,
    comment    => 'couchpotato user, created by Puppet',
    system     => true,
    managehome => true,
  }

  # Clone the couchpotato source using vcsrepo
  vcsrepo { $install_dir:
    ensure   => present,
    provider => git,
    source   => 'git://github.com/RuudBurger/CouchPotatoServer.git',
    owner    => $user,
    require  => User[$user],
  }

  file { '/etc/init.d/couchpotato':
    ensure  => file,
    content => template('couchpotato/ubuntu-init-couchpotato.erb'),
    mode    => '0755',
    require => Vcsrepo[$install_dir],
  }

  service {'couchpotato':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    require    => File['/etc/init.d/couchpotato'],
  }

}
