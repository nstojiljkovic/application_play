#
# Cookbook:: application_play
# Recipe:: opsworks_deploy
#
# Copyright:: 2018, Nikola Stojiljkovic, All Rights Reserved.

search("aws_opsworks_command").each do |command_conf|

  next unless command_conf['type'] == 'deploy'

  search("aws_opsworks_app").each do |app_conf|
    next unless (command_conf['args']['app_ids'] || []).include? app_conf['app_id']

    app_name = app_conf['shortname']
    app_attrs = app_conf['attributes']
    app_env = app_conf['environment']
    app_source = app_conf['app_source']

    next if app_name.nil? || app_attrs.nil? || app_env.nil? || app_source.nil?

    play_app = app_env[node['application_play']['opsworks']['app_env_vars']['required']]
    next if play_app.nil?

    ssl_configuration = app_conf['ssl_configuration'] || {}

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

    self_private_ip = nil
    play_app_nodes = []
    search("aws_opsworks_instance").each do |instance_conf|
      if instance_conf['role'].include? 'play_app'
        if instance_conf['self']
          self_private_ip = instance_conf['private_ip']
        end
        if instance_conf['status'] == 'online'
          play_app_nodes << instance_conf['private_ip']
        end
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
        java_settings node['application_play']['opsworks']['default_java_settings']
        systemd_settings node['application_play']['opsworks']['systemd_settings']

        if app_env['HTTP_PORT']
          port app_env['HTTP_PORT'].to_i
        end
        if app_env['HTTP_ADDRESS']
          address app_env['HTTP_ADDRESS']
        end

        if app_env['HTTPS_PORT']
          https_port app_env['HTTPS_PORT'].to_i
        end
        if app_env['HTTPS_ADDRESS']
          https_address app_env['HTTPS_ADDRESS']
        end

        enable_ssl app_conf['enable_ssl']
        ssl_cert ssl_configuration['certificate']
        ssl_key ssl_configuration['private_key']
        ssl_chain ssl_configuration['chain']
        security_properties node['application_play']['opsworks']['security_properties']

        version app_source['version']
        source_url app_source['url']
        source_user app_source['user']
        source_password app_source['password']
        source_checksum app_source['checksum']

        actor_system_name node['application_play']['opsworks']['actor_system_name']
        actor_provider node['application_play']['opsworks']['actor_provider']
        if node['application_play']['opsworks']['actor_provider'] != 'local'
          contact_points(play_app_nodes)
          required_contact_point_nr [play_app_nodes.size, node['application_play']['opsworks']['required_contact_point_nr']].min
        else
          contact_points([])
        end
        management_port node['application_play']['opsworks']['management_port']
        management_hostname self_private_ip
        remote_port node['application_play']['opsworks']['remote_port']
        remote_hostname self_private_ip
        enable_config_discovery node['application_play']['opsworks']['enable_config_discovery']

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
end