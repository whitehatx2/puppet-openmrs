class openmrs{
  
  package { "tzdata":
        ensure => installed
    }
  # Chaining the Notifications to control the order of the installation steps.
  Notify["OpenMRS-1.0.0"] ->  
    File["/etc/localtime"] ->
  Notify["OpenMRS-1.0.1"] ->  
    File["/etc/timezone"] ->
  Notify["OpenMRS-1.1"] ->  
    Exec["download-openmrs"] ->
  Notify["OpenMRS-2"] ->  
    File['/usr/share/tomcat6/.OpenMRS'] ->
  Notify["OpenMRS-3"] ->  
    Database_user['openmrs@localhost'] ->
    Database_grant['openmrs@localhost'] ->
  Notify["OpenMRS-4"] -> 
    Database['openmrs'] ->
  Notify["OpenMRS-5.0"] ->
    Exec['openmrs-module-kenyaemr-git-clone'] ->
  Notify["OpenMRS-5.1"] ->
    Exec['openmrs-module-kenyaemr-git-pull'] ->
  Notify["OpenMRS-5.2"] ->
    Exec['openmrs-module-kenyaemr-git-checkout'] ->
  Notify["OpenMRS-6"] ->
    Exec["maven-install"] ->
  Notify["OpenMRS-7"] ->
    Exec["wget-concept-dictionary"] ->
    Exec["apply-concept-dictionary"] ->	
  Notify["OpenMRS-8"] ->
    Exec["remove-previous-kenyaemr-distros"] ->
    File ["/usr/share/tomcat6/.OpenMRS/modules"] ->
  Notify["OpenMRS-9"] ->
	File ["/usr/share/tomcat6/.OpenMRS/openmrs-runtime.properties"]->
  Notify["OpenMRS-10"] ->
	File ["/opt/openmrs-backup-tools"] ->
  Notify["OpenMRS-11"] ->
	Exec ['configure-backup-cron']->
  Notify["OpenMRS-12"] ->
	File ['/etc/udev/rules.d/50-kemr.rules']->
  Notify["OpenMRS-13"] ->
	Exec ['reload-udev-rules']

  
  notify {"OpenMRS-1.0.0":
    message=> "Set up timezone to East Africa local time",
  }
  file { "/etc/localtime":
        require => Package["tzdata"],
        source => "/usr/share/zoneinfo/Africa/Nairobi",
    }

  notify {"OpenMRS-1.0.1":
    message=> "Set up timezone to East Africa",
  }
  file { "/etc/timezone":
        require => Package["tzdata"],
        source => "/usr/share/zoneinfo/Africa/Nairobi",
    }

  notify {"OpenMRS-1.1":
    message=> "Step 1. Download openmrs war from url and unzip to tomcat",
  } 	
  exec { 'download-openmrs':
    cwd     => '/usr/src',
    creates => '/usr/src/openmrs.war',
    command => '/usr/bin/wget \'http://iweb.dl.sourceforge.net/project/openmrs/releases/OpenMRS_1.9.1/openmrs.war\'',
    timeout => 5000,
  }
  
  file { '/var/lib/tomcat6/webapps/openmrs.war':
    ensure => present,
    source => '/usr/src/openmrs.war',
    require => Exec['download-openmrs'],
  }
  
  notify {"OpenMRS-2":
    message=> "Step 2. Create .OpenMRS folder",
  }
  file { '/usr/share/tomcat6/.OpenMRS':,
    ensure => directory,
    group => 'tomcat6',
    mode => '0775',
  }
  
  notify {"OpenMRS-3":
    message=> "Step 3. Create mysql user openmrs@localhost with temp password \'temp_openmrs\'.",
  }
  database_user{ 'openmrs@localhost':
    ensure        => present,
    password_hash => mysql_password('temp_openmrs'),
  }
  database_grant{'openmrs@localhost':
    privileges => [all],
  }
  notify {"OpenMRS-4":
    message=> "Step 4. Create database openmrs",
  }
  database{ 'openmrs':
    ensure => present,
    charset => 'utf8',
  } 
  notify {"OpenMRS-5.0":
    message=> "Step 5.0 Clone a copy of openmrs-module-kenyaemr.git to /usr/src/openmrs-module-kenyaemr",
  }
  exec{ 'openmrs-module-kenyaemr-git-clone':
    command => '/usr/bin/git clone --depth 1 git://github.com/I-TECH/openmrs-module-kenyaemr.git /usr/src/openmrs-module-kenyaemr',
    creates => '/usr/src/openmrs-module-kenyaemr',
    logoutput => 'true',
  }

  notify {"OpenMRS-5.1":
    message=> "Step 5.1 Fetch latest copy of openmrs-module-kenyaemr.git to /usr/src/openmrs-module-kenyaemr",
  }
  exec{ 'openmrs-module-kenyaemr-git-pull':
    cwd => '/usr/src/openmrs-module-kenyaemr',
    command => '/usr/bin/git pull',
    creates => '/usr/src/openmrs-module-kenyaemr',
    logoutput => 'true',
  }
  
  notify {"OpenMRS-5.2":
    message=> "Step 5.2 Checkout the current stable release",
  }
  exec{ 'openmrs-module-kenyaemr-git-checkout':
    cwd => '/usr/src/openmrs-module-kenyaemr',
    command => "/usr/bin/git checkout 2013.1",
    logoutput => 'true',
  }

  notify {"OpenMRS-6":
    message=> "Step 6. Run maven install to create distro.zip",
  }
  exec{ "maven-install":
    cwd => '/usr/src/openmrs-module-kenyaemr',
    command => '/usr/bin/mvn clean install -DbuildDistro=true -DsetupDatabase=true', 
    logoutput => 'on_failure',
    timeout => 5000, 	
  }

  notify {"OpenMRS-7":
    message=> "Step 7. wget concept dictionary.",
  }
  exec { "wget-concept-dictionary":
    cwd => '/usr/src',
    command => '/usr/bin/wget \'https://www.dropbox.com/s/lnfvd9r7cblpawr/kenyaemr-concepts-2013.1.sql\'',
    creates => '/usr/src/kenyaemr-concepts-2013.1.sql',
    timeout => 5000,
  }

  exec { "apply-concept-dictionary":
    cwd => '/usr/src',
    command => '/usr/bin/mysql openmrs < kenyaemr-concepts-2013.1.sql',
    timeout => 5000,	
  }

  notify {"OpenMRS-8":
    message=> "Step 8. Remove old distro then copy  new distro into tomcat6 modules directory (usr/share/tomcat6/.OpenMRS/modules)",
  }
  exec{ "remove-previous-kenyaemr-distros":
    cwd => '/usr/share/tomcat6/.OpenMRS/',
    command => '/bin/rm -rf /usr/share/tomcat6/.OpenMRS/modules/*.*',
  }
  file { '/usr/share/tomcat6/.OpenMRS/modules' :
		ensure => "directory",
		group => 'tomcat6',
		mode => '0775',
		source => "/usr/src/openmrs-module-kenyaemr/distro/target/distro" ,
		recurse => true
  }

  notify {"OpenMRS-9":
    message=> "Step 9. Create openmrs-runtime.properties file in the .OpenMRS directory",
  }
  file {"/usr/share/tomcat6/.OpenMRS/openmrs-runtime.properties":
    ensure => present,
    owner => 'root',
    group => 'tomcat6',
    mode => '0660',
    content => '
encryption.vector=kznZRqg+DbuOVWjhEl63cA==
connection.url=jdbc:mysql://localhost:3306/openmrs?autoReconnect=true&sessionVariables=storage_engine=InnoDB&useUnicode=true&characterEncoding=UTF-8
module.allow_web_admin=true
connection.username=openmrs
auto_update_database=false
encryption.key=UA0+SGpR1BG7538EsklrZQ==
connection.password=temp_openmrs

',
  }  

  notify {"OpenMRS-10":
    message=> "Install OpenMRS Backup Tools",
  }
  file { '/opt/openmrs-backup-tools':,
    ensure => directory,
    group => 'tomcat6',
    mode => '0775',
    source => 'puppet:///modules/openmrs/openmrs-backup-tools',
    recurse => true
  }

  notify {"OpenMRS-11":
    message=> "Configure backup cronjob to run daily at midnight",
  }
  exec { 'configure-backup-cron':
    command => '/opt/openmrs-backup-tools/setup.sh',
    timeout => 5000,
  }

  notify {"OpenMRS-12":
    message=> "Copying udev rules file to /etc/udev/rules.d",
  }
  file { '/etc/udev/rules.d/50-kemr.rules':,
  ensure => present,  
  source => 'puppet:///modules/openmrs/openmrs-backup-tools/50-kemr.rules',
  }

  notify {"OpenMRS-13":
    message=> "Reload udev rules",
  }
  exec { 'reload-udev-rules':
    command => '/sbin/udevadm control --reload-rules',
  }

}
