class openmrs {

  package { "mysql-server": ensure => installed }

  # Chaining the Notifications to control the order of the installation steps.
  Notify["OpenMRS-1"] ->  
    Exec["download-openmrs"] ->
  Notify["OpenMRS-2"] ->  
    File['/usr/share/tomcat6/.OpenMRS'] ->
    File['/usr/share/tomcat6/.OpenMRS/modules'] ->
  Notify["OpenMRS-3"] ->  
    Database_user['openmrs@localhost'] ->
    Database_grant['openmrs@localhost'] ->
  Notify["OpenMRS-4"] -> 
    Database['openmrs'] ->
  Notify["OpenMRS-5"] ->
    Exec['openmrs-module-kenyaemr-git-checkout'] ->
    Exec['openmrs-module-kenyaemr-git-fetch'] ->
    Exec['openmrs-module-kenyaemr-git-merge'] ->
  Notify["OpenMRS-6"] ->
    Exec["maven-install"] ->
  Notify["OpenMRS-7"] ->
    Exec["unzip-into-module-directory"] 
  #Notify["OpenMRS-8"]  

  notify {"OpenMRS-1":
    message=> "Step 1. Download openmrs.war to /usr/src/openmrs.war",
  }
  exec { 'download-openmrs':
    cwd     => '/usr/src',
    creates => '/usr/src/openmrs.war',
    command => '/usr/bin/wget \'http://iweb.dl.sourceforge.net/project/openmrs/releases/OpenMRS_1.9.1/openmrs.war\'',
  }

  notify {"OpenMRS-2":
    message=>"Step 2. Create .OpenMRS directory and modules subdirectory.",
  }
  file { '/usr/share/tomcat6/.OpenMRS':,
    ensure => directory,
    group => 'tomcat6',
    mode => '0775',
  }
  file { '/usr/share/tomcat6/.OpenMRS/modules':,
    ensure => directory,
    group => 'tomcat6',
    mode => '0775',
  }
  

/*
  # no longer in use
  exec { 'unzip-openmrs':
    command => '/usr/bin/unzip /usr/src/openmrs.war -d /var/lib/tomcat6/webapps/openmrs',
    creates => '/var/lib/tomcat6/webapps/openmrs',
  }
*/

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

  notify {"OpenMRS-5":
    message=> "Step 5. Clone, fetch, merge a copy of openmrs-module-kenyaemr.git to /usr/src/openmrs-module-kenyaemr",
  }
  exec{ 'openmrs-module-kenyaemr-git-clone':
    command => '/usr/bin/git clone --depth 1 git://github.com/djazayeri/openmrs-module-kenyaemr.git /usr/src/openmrs-module-kenyaemr',
    creates => '/usr/src/openmrs-module-kenyaemr',
    logoutput => 'true',
  }
  exec{ 'openmrs-module-kenyaemr-git-checkout':
    cwd => '/usr/src/openmrs-module-kenyaemr',
    command => '/usr/bin/git checkout tags/2012.2-dev',
    logoutput => 'true',
  }
  exec{ 'openmrs-module-kenyaemr-git-fetch':
    cwd => '/usr/src/openmrs-module-kenyaemr',
    command => '/usr/bin/git fetch ',
    logoutput => 'true',
  }
  exec{ 'openmrs-module-kenyaemr-git-merge':
    cwd => '/usr/src/openmrs-module-kenyaemr',
    command => '/usr/bin/git merge FETCH_HEAD',
    logoutput => 'true',
  }

  notify {"OpenMRS-6":
    message=> "Step 7. Run maven install to create distro.zip",
  }
  exec{ "maven-install":
    cwd => '/usr/src/openmrs-module-kenyaemr',
    command => '/usr/bin/mvn install -DbuildDistro=true -DsetupDatabase=true', 
    logoutput => 'on_failure',
  }

  notify {"OpenMRS-7":
    message=> "Step 8. Unzip distro into tomcat6 modules directory TODO, control chaining properly",
  }
  exec{ "unzip-into-module-directory": 
    cwd => '/usr/src/openmrs-module-kenyaemr/distro/target',
    command => '/usr/bin/unzip kenyaemr-distro-*-distro.zip /usr/share/tomcat6/.OpenMRS/modules',
  }
}
