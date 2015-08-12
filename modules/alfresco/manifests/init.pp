# Class: alfresco
#
# This module manages alfresco
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class alfresco(
	$user = "alfresco",	
	$database_name = "alfresco",
	$database_driver = "org.postgresql.Driver",
	$database_driver_jar = "postgresql-9.1-902.jdbc4.jar",
	$database_driver_source = "puppet:///modules/alfresco/db/postgresql-9.1-902.jdbc4.jar",
	$database_url = "jdbc:postgresql://localhost/alfresco",
	$database_user = "alfresco",
	$database_pass = "alfresco",
	$number = 7,
	$version = "4.2.a",
	$build = "4428",
	$alfresco_host = $fqdn,
	$alfresco_protocol = "http",
	$alfresco_port = "8080",
	$alfresco_contextroot = "alfresco",
	$share_host = $fqdn,
	$share_protocol = "http",
	$share_port = "8080",
	$share_contextroot = "share",
	$webapp_base = "/srv",
	$memory = "1024m",
	$imagemagick_version = "6.6.9",
	$smtp_host = "localhost",
	$smtp_port = "25",
	$smtp_username= "anonymous",
	$smtp_password= '',
	$smtp_encoding="UTF-8",
	$smtp_from_default="alfresco@${domain}",
	$smtp_auth="false",
	$mail_enabled="true",
	$mail_inbound_enabled="true",
	$mail_port="1025",
	$mail_domain=$domain,
	$mail_unknown_user="anonymous",
	$mail_allowed_senders=".*",
	$imap_enabled = "false",
	$imap_port = "1143",
	$imap_host = $fqdn,
	$authentication_chain="alfrescoNtlm1:alfrescoNtlm",
	$custom_settings=[]
) {
	
# configuration	
	$zip = "alfresco-community-${version}.zip"
	$download_url = "http://dl.alfresco.com/release/community/build-${build}/${zip}"
	$alfresco_dir = "${webapp_base}/${user}"
	$alfresco_home = "${alfresco_dir}/alfresco-home"
#        $alfresco_lib = "${webapp_base}/${user}/tomcat/lib"
	$alfresco_shared="${webapp_base}/${user}/shared"
	$alfresco_shared_classes="${webapp_base}/${user}/shared/classes"
	$alfresco_shared_extension="${webapp_base}/${user}/shared/classes/alfresco/extension"
	$alfresco_contentstore="$alfresco_home/contentstore"
	$alfresco_contentstore_deleted="$alfresco_home/contentstore.deleted"
	$alfresco_lucene_indexes="$alfresco_home/lucene-indexes"
	$alfresco_backup_lucene_indexes="$alfresco_home/backup-lucene-indexes"
	$tomcat_webapp_path="/var/lib/tomcat6/webapps"

	
	$share_webapp_context = $share_contextroot ? {
	  '/' => 'share',	
      '' => 'share',
      default  => "${share_contextroot}"
    }
    
    $share_webapp_war = $share_contextroot ? {
    	'' => "share.war",
    	'/' => "share.war",
    	default => "${share_contextroot}.war"	
    }
	
	$alfresco_webapp_context = $alfresco_contextroot ? {
	  '/' => 'alfresco',	
      '' => 'alfresco',
      default  => "${alfresco_contextroot}"
    }
    
    $alfresco_webapp_war = $alfresco_contextroot ? {
    	'' => "alfresco.war",
    	'/' => "alfresco.war",
    	default => "${alfresco_contextroot}.war"	
    }
	
# required packages
	if (!defined(Package['unzip'])) {
		package { "unzip":
			ensure => present,
		}	
	}
	

   ### exec { "add-apt-repository-swftools":
        ###command => "/usr/bin/apt-get install -y swftools",

	
###        notify  => Exec["apt-update-swftools"],
        ###require => Package["python-software-properties"],
    ###}

	package { "imagemagick":
		ensure => latest,
	}
	
	package { "swftools":
		ensure => latest,
###		require => Exec["apt-update-swftools"],
	}
	
	package { "libreoffice":
		ensure => latest,
	}
	
# download and extract alfresco


	file { $alfresco_dir:
		ensure => directory,
		mode => 0775,
		owner => $user,
		group => $user,
		require => Package["tomcat6"],
			   
	     }

	file { $alfresco_home:
		ensure => directory,
		mode => 0775,
		owner => $user,
		group => $user,
		require => [ Package["tomcat6"], File[$alfresco_dir],],
	}

	file { $alfresco_shared:
                ensure => directory,
                mode => 0775,
                owner => $user,
                group => $user,
                require => [ Package["tomcat6"], File[$alfresco_dir],],
             }



	file { $alfresco_shared_classes:
                ensure => directory,
                mode => 0775,
                owner => $user,
                group => $user,
		require => [ Package["tomcat6"], File[$alfresco_shared],],
             }

	file { $alfresco_shared_extension:
		ensure => directory,
		mode => 0775,
                owner => $user,
                group => $user,
		require => [ Package["tomcat6"], File[$alfresco_shared_classes],], 
             }

	file { $alfresco_contentstore:
                ensure => directory,
                mode => 0775,
                owner => $user,
                group => $user,
		require => [ Package["tomcat6"], File[$alfresco_home],],
        }

  file { $alfresco_contentstore_deleted:
                ensure => directory,
                mode => 0775,
                owner => $user,
                group => $user,
		require => [ Package["tomcat6"], File[$alfresco_home],],
        }



        file { $alfresco_lucene_indexes:
                ensure => directory,
                mode => 0775,
                owner => $user,
                group => $user,
		require => [ Package["tomcat6"], File[$alfresco_home],],
        }



        file { $alfresco_backup_lucene_indexes:
                ensure => directory,
                mode => 0775,
                owner => $user,
                group => $user,
		require => [ Package["tomcat6"], File[$alfresco_home],],
        }



        file { "alfresco-global.properties":
                path => "${alfresco_dir}/shared/classes/alfresco-global.properties",
                content => template("alfresco/alfresco-global.properties.erb"),
		require => [ Package["tomcat6"], File["${alfresco_dir}/shared/classes/alfresco"],],
        }

        file { "${alfresco_dir}/shared/classes/alfresco":
                ensure => directory,
                owner => $user,
                group => $user,
                mode => 0755,
		require => [ Package["tomcat6"], File[$alfresco_shared_classes],],
        }

        file { "${alfresco_dir}/shared/classes/alfresco/web-extension":
                ensure => directory,
                owner => $user,
                group => $user,
                mode => 0755,
                require => File["${alfresco_dir}/shared/classes/alfresco"],
        }



	file { 'alfresco-db-driver':
                path => "/usr/share/tomcat6/lib/${database_driver_jar}",
                source => $database_driver_source,
                ensure => file,
                owner => $user,
                group => $user,
                require => Package["tomcat6"],
        }

	


	exec { "download-alfresco":
		command => "/usr/bin/wget -O /tmp/${zip} ${download_url}",
		creates => "/tmp/${zip}",
		timeout => 1200,	
	}

	
	
	file { "/tmp/${zip}":
		ensure => file,
		mode => 0755,
		require => Exec["download-alfresco"],
	}


	
	exec { "extract-alfresco" :
		command => "/usr/bin/unzip ${zip} -d /tmp/alfresco-${version}",
		creates => "/tmp/alfresco-${version}/web-server/webapps/alfresco.war",
		onlyif => "/usr/bin/test ! -f $tomcat_webapp_path/$alfresco_webapp_war",
		require => [
			File["/tmp/${zip}"],
			Package["unzip"],
			Package["tomcat6"],
		],
		notify => [
			Exec['move-alfresco-war'],
	###		Exec['move-share-war'],
		#	Exec['move-share-war']
		],
		cwd => "/tmp",
		user => "root" 	
	} ->

	exec { "copy-alfresco-extensions":
                command => "/bin/cp -rp /tmp/alfresco-${version}/web-server/shared/classes/alfresco/extension/* $alfresco_shared_extension/",
                #refreshonly => true,
                onlyif => "/usr/bin/test ! -f $tomcat_webapp_path/$alfresco_webapp_war",
                user => "root",
                require => [
                        Exec["extract-alfresco"],
                        Package["tomcat6"],
                        File[$alfresco_shared_extension],
                ],
                } ->



	exec { "move-alfresco-war":
               command => "/bin/cp -rp /tmp/alfresco-${version}/web-server/webapps/$alfresco_webapp_war $tomcat_webapp_path/${alfresco_webapp_war}",
		onlyif => "/usr/bin/test ! -f $tomcat_webapp_path/$alfresco_webapp_war",
		
             #   refreshonly => true,
                user => "root",
               require => [
                      Exec["extract-alfresco"],
                ]
        } ->


        file { $alfresco_webapp_war:
#		replace => no,
                ensure => present,
                path => "$tomcat_webapp_path/${alfresco_webapp_war}",
                owner => $user,
                group => $user,
               mode => 0644,
	       before => Tomcat::Service['default'],
               require => [ Exec['move-alfresco-war'],
			    File['/etc/default/tomcat6'],
			]
	      	
        } ->

	exec { "copy-share-extensions":
                command => "/bin/cp -rp /tmp/alfresco-${version}/web-server/shared/classes/alfresco/web-extension/* ${alfresco_dir}/shared/classes/alfresco/web-extension ;/bin/mv ${alfresco_dir}/shared/classes/alfresco/web-extension/share-config-custom.xml.sample ${alfresco_dir}/shared/classes/alfresco/web-extension/share-config-custom.xml",
                #refreshonly => true,
                onlyif => "/usr/bin/test ! -f $tomcat_webapp_path/$share_webapp_war",
                user => "root",
                require => [
  #                      Exec["extract-alfresco"],
                        Package["tomcat6"],
                        File["$alfresco_shared_extension"],
                ],
                } ->



	exec { "move-share-war":
                command => "/bin/cp -rp /tmp/alfresco-${version}/web-server/webapps/share.war $tomcat_webapp_path/${share_webapp_war}",
#                refreshonly => true,

		onlyif => "/usr/bin/test ! -f $tomcat_webapp_path/$share_webapp_war",
                user => "root",
                require => [
 #                       Exec["copy-share-extensions"],
                ]
        }->

	file { "share-war":
                ensure => file,
                path => "$tomcat_webapp_path/${share_webapp_war}",
                owner => $user,
                group => $user,
                mode => 0644,
#                require => Exec["move-share-war"],
        } ->


	file {'alfresco-4.2.a':
                ensure => absent,
                path => '/tmp/alfresco-4.2.a',
                purge => true,
                force => true,
		require =>[ File[$alfresco_webapp_war],
			    Exec["copy-alfresco-extensions"],	
			    Exec["move-alfresco-war"],
			    		    	
			]		

                } 


	
	
	



}	
