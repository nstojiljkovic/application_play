require 'json'

include ApplicationDeployHelper

action :deploy do
  deploy_path = new_resource.parent.path
  deploy_user = new_resource.parent.owner
  deploy_group = new_resource.parent.group
  app_name = new_resource.parent.name
  app_version = new_resource.version
  service_name = new_resource.service_name

  ::Chef::Log.info("Deploying Play framework application #{app_name} to #{deploy_path} ...")

  unless new_resource.source_user.nil? || new_resource.source_password.nil?
    headers = {"Authorization" => "Basic #{ Base64.encode64("#{new_resource.source_user}:#{new_resource.source_password}").gsub("\n", "") }"}
  else
    headers = {}
  end

  directory "#{deploy_path}/.cache/releases/#{app_version}" do
    owner deploy_user
    group deploy_group

    recursive true
    action :create
  end

  remote_file "#{deploy_path}/.cache/releases/#{app_version}/#{app_name}-#{app_version}.tgz" do
    owner deploy_user
    group deploy_group

    source new_resource.source_url
    backup false
    checksum new_resource.source_checksum
    use_conditional_get true
    use_etag true
    use_last_modified true
    show_progress true
    headers(headers)
    retries 3
    owner deploy_user
    group deploy_group

    unless new_resource.force_deploy
      not_if "test -d #{deploy_path}/releases/#{app_version}/bin"
    end
  end

  directory "#{deploy_path}/releases/#{app_version}" do
    owner deploy_user
    group deploy_group

    recursive true
    action :create
  end

  execute "Extract tar: #{deploy_path}/.cache/releases/#{app_version}/#{app_name}-#{app_version}.tgz to: #{deploy_path}/releases/#{app_version}" do
    user deploy_user
    group deploy_group

    command <<-EOH
      tar xzvf #{deploy_path}/.cache/releases/#{app_version}/#{app_name}-#{app_version}.tgz -C #{deploy_path}/releases/#{app_version} --strip-components=1;
      chown -Rf #{deploy_user}:#{ deploy_group} #{deploy_path}/releases/#{app_version};
    EOH
    cwd "#{deploy_path}/.cache/releases/#{app_version}"

    unless new_resource.force_deploy
      not_if "test -d #{deploy_path}/releases/#{app_version}/bin"
    end
  end

  link "Delete #{deploy_path}/current" do
    target_file "#{deploy_path}/current"
    action :delete
    only_if "test -L #{deploy_path}/current"
  end

  link "Create #{deploy_path}/current" do
    owner deploy_user
    group deploy_group

    target_file "#{deploy_path}/current"
    to "#{deploy_path}/releases/#{app_version}"
  end

  config_file = ::File.join(deploy_path, new_resource.config_file)

  directory ::File.dirname(config_file) do
    owner deploy_user
    group deploy_group

    recursive true
    action :create
  end

  def settings_hash_to_str(settings = {}, str = '', indent = 0, is_arr = false)
    res = str
    settings.each_with_index do |kv, index|
      if !is_arr #kv.respond_to?(:each_pair)
        key = kv[0]
        value = kv[1]
      else
        key = nil
        value = kv
      end
      if value.respond_to?(:each_pair)
        # hash
        if key.nil?
          res += "\n" + (" " * indent) + "{"
        else
          res += "\n" + (" " * indent) + key.to_s + " {"
        end
        res = settings_hash_to_str(value, res, indent + 2)
        res += "\n" + (" " * indent) + "}"
      elsif value.respond_to?(:each)
        # array
        if key.nil?
          res += "\n" + (" " * indent) + "["
        else
          res += "\n" + (" " * indent) + key.to_s + " = ["
        end
        res = settings_hash_to_str(value, res, indent + 2, true)
        res += "\n" + (" " * indent) + "]"
      else
        # string, symbol, number...
        if key.nil?
          res += "\n" + (" " * indent) + value.to_json
        else
          res += "\n" + (" " * indent) + key.to_s + " = " + value.to_json
        end
      end
      if key.nil? && index != settings.size - 1
        res += ","
      end
    end
    res.strip
  end

  settings = Hash.new {|hash, key| hash[key] = Hash.new(&hash.default_proc)}
  settings['akka']['actor']['provider'] = new_resource.actor_provider
  settings['play']['akka']['actor-system'] = new_resource.actor_system_name
  settings['play']['filters']['hosts']['allowed'] = new_resource.domains
  settings['akka']['management']['http']['port'] = new_resource.management_port
  settings['akka']['management']['http']['bind-port'] = new_resource.management_port
  unless new_resource.management_hostname.nil?
    settings['akka']['management']['http']['hostname'] = new_resource.management_hostname
    settings['akka']['management']['http']['bind-hostname'] = new_resource.management_hostname
  end
  if new_resource.actor_provider == 'cluster'
    # @see https://github.com/akka/akka-management/blob/master/cluster-bootstrap/src/main/resources/reference.conf
    settings['akka']['management']['cluster']['bootstrap']['contact-point-discovery']['effective-name'] =
        new_resource.actor_system_name

    if new_resource.enable_config_discovery
      settings['akka']['discovery']['method'] = 'config'
      settings['akka']['discovery']['config']['services'][new_resource.actor_system_name]['endpoints'] =
          new_resource.contact_points.map do |contact_point|
            {
                'host' => contact_point,
                'port' => new_resource.management_port,
            }
          end
    else
      settings['akka']['cluster']['seed-nodes'] =
          new_resource.contact_points.map do |contact_point|
            "akka.tcp://#{new_resource.actor_system_name}@#{contact_point}:#{new_resource.remote_port}"
          end
    end
  end
  if new_resource.actor_provider == 'cluster' || new_resource.actor_provider == 'remote'
    settings['akka']['management']['cluster']['bootstrap']['contact-point-discovery']['required-contact-point-nr'] = new_resource.required_contact_point_nr
    settings['akka']['remote']['netty']['tcp']['port'] = new_resource.remote_port
    unless new_resource.remote_hostname.nil?
      settings['akka']['remote']['netty']['tcp']['hostname'] = new_resource.remote_hostname
    end
  end

  ::Chef::Log.info(settings_hash_to_str(Chef::Mixin::DeepMerge.deep_merge(new_resource.settings, settings)))

  template config_file do
    owner deploy_user
    group deploy_group
    mode '0640'

    cookbook new_resource.config_template_cookbook
    source new_resource.config_template_source

    variables lazy {
      {
          'include_conf' => ::Dir[::File.join(deploy_path, 'current/conf/application.conf')].first,
          'settings' => settings_hash_to_str(Chef::Mixin::DeepMerge.deep_merge(new_resource.settings, settings)),
          'enable_ssl' => new_resource.enable_ssl,
          'https_port' => new_resource.https_port,
      }
    }
  end

  env_file = ::File.join(deploy_path, new_resource.env_file)

  directory ::File.dirname(env_file) do
    owner deploy_user
    group deploy_group

    recursive true
    action :create
  end

  file env_file do
    owner deploy_user
    group deploy_group

    content (new_resource.app_env || {}).collect {|k, v| "#{k}=#{v}"}.join("\n")
    mode '640'
  end

  java_settings = new_resource.java_settings
  if new_resource.autoconfigure_memory
    memory_in_megabytes = case node['os']
                          when /.*bsd/
                            node['memory']['total'].to_i / 1024 / 1024
                          when 'linux'
                            node['memory']['total'][/\d*/].to_i / 1024
                          when 'darwin'
                            node['memory']['total'][/\d*/].to_i
                          when 'windows', 'solaris', 'hpux', 'aix'
                            node['memory']['total'][/\d*/].to_i / 1024
                          end

    xmx = [
        [
            (memory_in_megabytes * new_resource.xmx_ratio).round,
            memory_in_megabytes - new_resource.xmx_leftover_min
        ].min,
        new_resource.xmx_min
    ].max
    xms = (xmx * new_resource.xms_xmx_ratio).round
    java_settings = java_settings + " -J-Xms#{xms}m -J-Xmx#{xmx}m"
  end

  security_properties_file = ::File.join(deploy_path, new_resource.security_properties_file)
  java_settings = java_settings + " -Djava.security.properties=#{security_properties_file}"
  file security_properties_file do
    owner deploy_user
    group deploy_group

    content (new_resource.security_properties || {}).collect {|k, v| "#{k}=#{v}"}.join("\n")
    mode '640'
  end

  if new_resource.enable_ssl
    pem_file = ::File.join(Chef::Config['file_cache_path'], "#{app_name}.pem")
    pkcs12_file = ::File.join(Chef::Config['file_cache_path'], "#{app_name}.pfx")
    jks_file = ::File.join(deploy_path, new_resource.jks_file)

    template pem_file do
      source "certificate.pem.erb"
      mode '0640'
      owner deploy_user
      group deploy_group
      backup false
      variables(
          {
              :cert => new_resource.ssl_cert,
              :key => new_resource.ssl_key,
              :chain => new_resource.ssl_chain,
          }
      )
      action :create
    end

    jks_password = new_resource.jks_password

    execute "Generate #{jks_file}" do
      command <<-EOH
        openssl pkcs12 -export -in #{pem_file} -inkey #{pem_file} -out #{pkcs12_file} -name #{app_name} -passin pass:#{jks_password} -passout pass:#{jks_password} &&
        rm -f #{jks_file} &&
        keytool -importkeystore -srckeystore #{pkcs12_file} -srcstoretype PKCS12  -alias #{app_name} -srcstorepass #{jks_password} -deststorepass #{jks_password} -destkeypass #{jks_password} -destkeystore #{jks_file} &&
        chown #{deploy_user}:#{deploy_group} #{jks_file} &&
        chmod 640 #{jks_file} &&
        rm -f #{pem_file} &&
        rm -f #{pkcs12_file}
      EOH

      unless new_resource.force_deploy
        not_if "test -d #{jks_file}"
      end
    end

    java_settings = java_settings + " -Dhttps.address=#{new_resource.https_address}"
    java_settings = java_settings + " -Dhttps.port=#{new_resource.https_port}"
    java_settings = java_settings + " -Dplay.server.https.keyStore.path=#{jks_file}"
    java_settings = java_settings + " -Dplay.server.https.keyStore.type=JKS"
    java_settings = java_settings + " -Dplay.server.https.keyStore.password=#{jks_password}"
  end

  systemd_unit "#{service_name}.service" do
    content lazy {
      executable_file = ::Dir[::File.join(deploy_path, 'current/bin', '*')].reject {|file| file.include?('.')}.first
      {
          'Unit' => {
              'Description' => new_resource.service_description,
              'After' => 'network.target',
          },
          'Service' => {
              'Type' => 'simple',
              'PIDFile' => "#{deploy_path}/RUNNING_PID",
              'User' => deploy_user,
              'Group' => deploy_group,
              'EnvironmentFile' => env_file,
              'WorkingDirectory' => "#{deploy_path}/current",
              'ExecStartPre' => "[ -e #{deploy_path}/RUNNING_PID ] && rm #{deploy_path}/RUNNING_PID",
              'ExecStart' => "#{executable_file} -Dpidfile.path=#{deploy_path}/RUNNING_PID -Dconfig.file=#{config_file} -Dhttp.port=#{new_resource.port} -Dhttp.address=#{new_resource.address} #{java_settings}",
              'ExecStop' => '/bin/kill $MAINPID',
              'ExecStopPost' => "[ -e #{deploy_path}/RUNNING_PID ] && rm #{deploy_path}/RUNNING_PID",
              'ExecRestart' => '/bin/kill $MAINPID',

              'RestartSec' => '3s',
              # 'Restart' => 'always',
              'Restart' => 'on-failure',
              # See http://serverfault.com/a/695863
              'AmbientCapabilities' => 'CAP_NET_BIND_SERVICE',
              'SuccessExitStatus' => 143,
              'LimitFSIZE' => 'infinity',
              'LimitCPU' => 'infinity',
              'LimitAS' => 'infinity',
              'LimitNOFILE' => 65536,
              'LimitNPROC' => 16384
          }.merge(new_resource.service_settings),
          'Install' => {
              'WantedBy' => 'multi-user.target'
          }
      }
    }
    action [:create, :enable, :start]
  end

  ruby_block "#{app_name} cleanup old releases" do
    block do
      cleanup!(deploy_path, new_resource.keep_releases, app_version)
      cleanup!("#{deploy_path}/.cache", new_resource.keep_releases, app_version)
    end
    action :run
  end
end

action :start do
  service new_resource.service_name do
    action :start
  end
end

action :stop do
  service new_resource.service_name do
    action :stop
  end
end

action :restart do
  service new_resource.service_name do
    action :restart
  end
end
