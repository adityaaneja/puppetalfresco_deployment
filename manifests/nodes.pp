###node 'lamp-1' {

#class { 'apache':                # use the "apache" module
#    default_vhost => false,        # don't use the default vhost
#    default_mods => false,         # don't load default mods
#    mpm_module => 'prefork',        # use the "prefork" mpm_module
#  }
#   include apache::mod::php        # include mod php
#   apache::vhost { 'example.com':  # create a vhost called "example.com"
#    port    => '80',               # use port 80
#    docroot => '/var/www/html',     # set the docroot to the /var/www/html
#  }

# class { 'mysql::server':
#    root_password => 'mysql',
#  }

# file { 'info.php':                                # file resource name
#    path => '/var/www/html/info.php',               # destination path
#    ensure => file,
#    require => Class['apache'],                     # require apache class be used
#    source => 'puppet:///modules/apache/info.php',  # specify location of file to be copied
#  }

###}

node 'lamp-1' {





include apache::mod::proxy_ajp

apache::vhost { 'alfresco-test.srv.ualberta.ca':
	port => 80,
	default_vhost => true,
	servername => 'alfresco-test.srv.ualberta.ca',
	access_log => true,
	access_logs => ['alfresco-test_access.log'],
	proxy_pass => [{'path' => '/alfresco','url'=>'ajp://localhost:8009/alfresco'},
		       {'path' => '/share','url'=>'ajp://localhost:8009/share'},],
	docroot => '/var/www/html',
	}

class {'apache':
	
	service_ensure => running,
	service_enable => false,

}

class { 'tomcat':
  install_from_source => false,
}
class { 'epel': }->
tomcat::instance{ 'default':
  package_name => 'tomcat6',
}->

tomcat::config::server::connector { 'tomcat6-ajp':
  catalina_base         => '/var/lib/tomcat6',
  port                  => '8009',
  protocol              => 'AJP/1.3',
  additional_attributes => {
    'redirectPort' => '8443'
  },
}->

tomcat::service { 'default':
  use_jsvc     => false,
  use_init     => true,
  service_name => 'tomcat6',
}


tomcat::config::server::context {'alfresco.war':
doc_base => 'alfresco.war',
context_ensure => present,
catalina_base => '/var/lib/tomcat6/alfresco.war',
parent_service        => 'Catalina',
parent_engine         => 'Catalina',
parent_host           => 'localhost',
server_config         => '/etc/tomcat6/server.xml',
additional_attributes => {
          'path' => '/alfresco',
        },
require => Exec['copy-alfresco-extensions'],	
}


tomcat::config::server::context {'share.war':
doc_base => 'share.war',
context_ensure => present,
catalina_base => '/var/lib/tomcat6/share.war',
parent_service        => 'Catalina',
parent_engine         => 'Catalina',
parent_host           => 'localhost',
server_config         => '/etc/tomcat6/server.xml',
additional_attributes => {
          'path' => '/share',
        },
require => File['share-war'],
}


class { 'postgresql::server':
  ip_mask_deny_postgres_user => '0.0.0.0/32',
  ip_mask_allow_all_users    => '0.0.0.0/0',
  listen_addresses           => '*',
  ipv4acls                   => ['host all all 192.168.122.0/24 ident'],
  postgres_password          => 'postgres',
  service_enable => false,
  service_ensure => running,
}

postgresql::server::role { 'alfresco':
  password_hash => postgresql_password('alfresco', 'alfresco'),
}

postgresql::server::db { 'alfresco':
  user     => 'alfresco',
  password => postgresql_password('alfresco', 'alfresco'),
}

postgresql::server::database_grant { 'alfresco':
  privilege => 'ALL',
  db        => 'alfresco',
  role      => 'alfresco',
}


group {'alfresco':
	ensure => present,
	}

user { 'alfresco':
	ensure => present,
	groups => ['alfresco'],
	}
user {'tomcat6':
	ensure => present,
	groups => ['alfresco'],
	}

file {'remove_tomcat_share':
	ensure => link,
	path => '/var/lib/tomcat6/shared',
	purge => true,
	force => true,
	target => '/srv/alfresco/shared',
	require => File['/srv/alfresco/shared'],
	}

file {'/etc/default/tomcat6':
	ensure => present,
	}->
	file_line {'Append a line':
		path => '/etc/default/tomcat6',
		line => 'JAVA_OPTS="-Djava.awt.headless=true -Xmx512m -XX:+UseConcMarkSweepGC"',
		require => Package['tomcat6'],
		notify => Tomcat::Service['default'],
		}





include alfresco 



}
