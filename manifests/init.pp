class openmrs {
  file { '/usr/share/tomcat6/.OpenMRS':,
    ensure => directory,
    group => 'tomcat6',
    mode => '0775',
  }

  exec { 'download-openmrs':
    cwd     => '/usr/src',
    creates => '/usr/src/openmrs.war',
    command => '/usr/bin/wget \'http://iweb.dl.sourceforge.net/project/openmrs/releases/OpenMRS_1.9.1/openmrs.war\''
  }

  exec { 'unzip-openmrs':
    command => '/usr/bin/unzip /usr/src/openmrs.war -d /var/lib/tomcat6/webapps/openmrs',
    creates => '/var/lib/tomcat6/webapps/openmrs',
    require => Exec['download-openmrs'],
  }
}
