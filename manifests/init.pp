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
  $data_dir = '/var/couchpotato',
  $user = 'couchpotato',
  $address = '0.0.0.0',
  $port = '8082',
) {

  # Install required  dependencies. Puppet sucks with having packages required by multiple modules.
  if ! defined(Package['git']) {
	package { 'git':
	  ensure => installed,
	}
  }
  
  if ! defined(Package['python']) {
	package { 'python':
	  ensure => installed,
	}
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
  
  file { '/etc/default/couchpotato':
    ensure  => file,
	content => template('couchpotato/ubuntu.default.erb'),
	mode    => '644',
	require => File['/etc/init.d/couchpotato'],
  }
  
  file { $data_dir:
    ensure  => directory,
	mode    => '775',
	owner   => $user,
	group   => $user,
	require => User[$user],
  }
  
  # this is a hack to make it start up on the correct port we define, it's oddly 
  # done only via the UI and defaults to 5050. https://github.com/RuudBurger/CouchPotatoServer/issues/242
  file { "${data_dir}/settings.conf":
    ensure  => file,
	content => template('couchpotato/settings.conf.erb'),
	mode    => '666',
	owner   => $user,
	require => [User[$user], File[$data_dir]],
  }

  service {'couchpotato':
    ensure     => running,
    enable     => true,
    hasrestart => false,
    hasstatus  => false,
    require    => [File['/etc/default/couchpotato'], File[$data_dir]]
  }

}
