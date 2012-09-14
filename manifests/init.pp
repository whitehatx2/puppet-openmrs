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
    Exec["remove-previous-kenyaemr-distros"] ->
    Exec["unzip-into-module-directory"]  ->
  Notify["OpenMRS-8"] ->
    Exec["wget-moduledistro"] ->
    Exec["wget-logic"] ->
  Notify["OpenMRS-9"] ->
    Exec["wget-concept-dictionary"] ->
    Exec["apply-concept-dictionary"] ->
  Notify["OpenMRS-10"] ->
    File ["/usr/share/tomcat6/.OpenMRS/openmrs-runtime.properties"] 

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
    message=> "Step 6. Run maven install to create distro.zip",
  }
  exec{ "maven-install":
    cwd => '/usr/src/openmrs-module-kenyaemr',
    command => '/usr/bin/mvn install -DbuildDistro=true -DsetupDatabase=true', 
    logoutput => 'on_failure',
  }

  notify {"OpenMRS-7":
    message=> "Step 7. Unzip distro into tomcat6 modules directory (usr/share/tomcat6/.OpenMRS/modules)",
  }
  exec{ "remove-previous-kenyaemr-distros":
    cwd => '/usr/share/tomcat6/.OpenMRS/modules',
    command => '/bin/rm -rf kenyaemr-distro-*',
  }
  exec{ "unzip-into-module-directory": 
    cwd => '/usr/src/openmrs-module-kenyaemr/distro/target',
    command => '/usr/bin/unzip -fo kenyaemr-distro-*-distro.zip -d /usr/share/tomcat6/.OpenMRS/modules',
  }

  notify {"OpenMRS-8":
    message=> "Step 8. wget moduledistro and logic omods.",
  }
  exec { "wget-moduledistro":
    cwd => '/usr/share/tomcat6/.OpenMRS/modules',
    command => '/usr/bin/wget \'https://modules.openmrs.org/modules/download/moduledistro/moduledistro-1.2.omod\'',
    creates => '/usr/share/tomcat6/.OpenMRS/modules/moduledistro-1.2.omod',
  }
  exec { "wget-logic":
    cwd => '/usr/share/tomcat6/.OpenMRS/modules',
    command => '/usr/bin/wget \'https://modules.openmrs.org/modules/download/logic/logic-0.5.2.omod\'',
    creates => '/usr/share/tomcat6/.OpenMRS/modules/logic-0.5.2.omod',
  }

  notify {"OpenMRS-9":
    message=> "Step 9. wget concept dictionary.",
  }
  exec { "wget-concept-dictionary":
    cwd => '/usr/src',
    command => '/usr/bin/wget \'https://openmrs:openmrs@download.cirg.washington.edu/openmrs/dictionary/openmrs_concepts_1.9.0_20120727.sql\'',
    creates => '/usr/src/openmrs_concepts_1.9.0_20120727.sql';
  }
  exec { "apply-concept-dictionary":
    cwd => '/usr/src',
    command => '/usr/bin/mysql openmrs < openmrs_concepts_1.9.0_20120727.sql',
  }

  notify {"OpenMRS-10":
    message=> "Step 10. Create openmrs-runtime.properties file in the .OpenMRS directory",
  }
  file {"/usr/share/tomcat6/.OpenMRS/openmrs-runtime.properties":
    content => '
      connection.username=openmrs
      connection.password=temp_openmrs
      connection.url=jdbc:mysql://localhost:3306/openmrs?autoReconnect=true&sessionVariables=storage_engine=InnoDB&useUnicode=true&characterEncoding=UTF-8
      module.allow_web_admin=false
      auto_update_database=false
',
  }

  #

  #notify {"OpenMRS-11":
  #  message=> "Step 11. Alter the init.d/tomcat6 file",
  #}
  # plan:
  #   use sed to delete the three configuration lines (if they exist)
  #   use sed to insert the three new configuration lines
  #exec {"alter-init.d-tomcat6-sed-runtimeproperties":
  #  cwd => '/etc/init.d',
  #  exec => ' 

  # this fail task is used to short circuit this script for testing
  #exec {"fail":
  #  cwd => '/nowhere/fail/fail/fail',
  #  command => '/bin/echo 0',
  #}

  # TODO: copy to the war file to the tomcat webapps directory
    

}
