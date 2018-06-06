default['application_play']['opsworks']['autoconfigure_memory'] = true
default['application_play']['opsworks']['xms_xmx_ratio'] = 0.25
default['application_play']['opsworks']['xmx_ratio'] = 1.0
default['application_play']['opsworks']['xmx_min'] = 128
default['application_play']['opsworks']['xmx_leftover_min'] = 256
default['application_play']['opsworks']['install_java'] = true
default['application_play']['opsworks']['manage_users'] = true
default['application_play']['opsworks']['apps_root_dir'] = '/home'
default['application_play']['opsworks']['app_env_vars']['required'] = 'PLAY_APP'
default['application_play']['opsworks']['app_env_vars']['user_uid'] = 'APP_USER_UID'
default['application_play']['opsworks']['keep_releases'] = 3
default['application_play']['opsworks']['force_deploy'] = true
default['application_play']['opsworks']['default_settings'] = {
  'play.evolutions.autoApply' => 'true'
}
