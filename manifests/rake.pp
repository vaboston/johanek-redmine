#Class redmine::rake - DB migrate/prep tasks
class redmine::rake {
  if $redmine::create_vhost {
    $notify_httpd = Class['apache::service']
  } else {
    $notify_httpd = undef
  }

  Exec {
    path        => ['/bin','/usr/bin', '/usr/local/bin'],
    environment => ['HOME=/root','RAILS_ENV=production','REDMINE_LANG=en'],
    provider    => 'shell',
    cwd         => $redmine::install_dir,
  }

  # Create session store
  exec { 'session_store':
    command => 'rake generate_session_store && touch .session_store',
    creates => "${redmine::install_dir}/.session_store",
  }

  # Perform rails migrations
  exec { 'rails_migrations':
    command     => 'rake db:migrate',
    notify      => Exec['plugin_migrations'],
    refreshonly => true,
  }

  # Perform plugin migrations
  exec { 'plugin_migrations':
    command     => 'rake redmine:plugins:migrate',
    notify      => $notify_httpd,
    refreshonly => true,
  }

  # Seed DB data
  exec { 'seed_db':
    command => 'rake redmine:load_default_data && touch .seed',
    creates => "${redmine::install_dir}/.seed",
    notify  => $notify_httpd,
    require => Exec['rails_migrations'],
  }

}
