class concepts {
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
      require => Exec['wget-concept-dictionary'],	
    }
}