class openmrs::db {

    database_user{ 'openmrs@10.0.2.16':
      ensure        => present,
      password_hash => mysql_password('temp_openmrs'),
    }
    database_grant{'openmrs@10.0.2.16':
      privileges => [all],
    }
    database{ 'openmrs':
      ensure => present,
      charset => 'utf8',
    }    
    class { 'mysql::config':
     bind_address  => '10.0.2.17',     
   }
}