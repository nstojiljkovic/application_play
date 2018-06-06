#
# Cookbook:: application_play
# Recipe:: opsworks_deploy
#
# Copyright:: 2018, Nikola Stojiljkovic, All Rights Reserved.

search("aws_opsworks_app").each do |app_conf|
  app_name = app_conf['shortname']
  app_attrs = app_conf['attributes']
  app_env = app_conf['environment']
  app_source = app_conf['app_source']

  next if app_name.nil? || app_attrs.nil? || app_env.nil? || app_source.nil?

  play_app = app_env[node['application_play']['opsworks']['app_env_vars']['required']]
  next if play_app.nil?

  user_home_root = node['application_play']['opsworks']['apps_root_dir']

  deploy_path = "#{user_home_root}/#{app_name}"
  deploy_user = app_name
  deploy_group = app_name

  if node['application_play']['opsworks']['manage_users']
    app_user_uid = app_env[node['application_play']['opsworks']['app_env_vars']['user_uid']]
    next if app_user_uid.nil? || app_user_uid.to_i == 0
    app_user_uid = app_user_uid.to_i

    directory user_home_root do
      owner 'root'
      group 'root'

      mode '0755'
      recursive true
      action :create
    end

    group app_name do
      gid app_user_uid
    end

    user app_name do
      username app_name
      manage_home true
      home deploy_path
      uid app_user_uid
      gid app_user_uid
      shell '/sbin/nologin'
    end

    directory deploy_path do
      owner app_name
      group app_name

      mode '0750'
      recursive true
      action :create
    end
  end

  application app_name do
    owner deploy_user
    group deploy_group

    path deploy_path

    play app_name do
      app_env app_conf['environment']
      domains app_conf['domains']
      settings node['application_play']['opsworks']['default_settings']

      if app_env['HTTP_PORT']
        port app_env['HTTP_PORT'].to_i
      end
      if app_env['HTTP_ADDRESS']
        address app_env['HTTP_ADDRESS']
      end

      version app_source['version']
      source_url app_source['url']
      source_user app_source['user']
      source_password app_source['password']
      source_checksum app_source['checksum']

      keep_releases node['application_play']['opsworks']['keep_releases']
      force_deploy node['application_play']['opsworks']['force_deploy']

      if node['application_play']['opsworks']['autoconfigure_memory']
        autoconfigure_memory true
        xms_xmx_ratio node['application_play']['opsworks']['xms_xmx_ratio']
        xmx_ratio node['application_play']['opsworks']['xmx_ratio']
        xmx_min node['application_play']['opsworks']['xmx_min']
        xmx_leftover_min node['application_play']['opsworks']['xmx_leftover_min']
      end
    end

    action [:deploy]
  end
end