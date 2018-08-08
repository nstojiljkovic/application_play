include Poise(parent: :application)

actions(:deploy, :start, :stop, :restart)
default_action :deploy

property :service_name, :kind_of => String, :required => false, :default => lazy {|a| a.name}
property :service_description, :kind_of => String, :required => false, :default => lazy {|a| "#{a.name} service"}
property :service_settings, :kind_of => Hash, :required => false, :default => {}

property :port, :kind_of => Integer, :required => true, :default => 9000
property :address, :kind_of => String, :required => true, :default => "0.0.0.0"

property :actor_system_name, :kind_of => String, :required => true, :default => "application"
property :actor_provider, :kind_of => String, :required => true, :default => "local"
property :contact_points, :kind_of => Array, :required => true, :default => []
property :management_port, :kind_of => Integer, :required => true, :default => 8558
property :management_hostname, :kind_of => String, :required => false
property :remote_port, :kind_of => Integer, :required => true, :default => 2552
property :remote_hostname, :kind_of => String, :required => false
property :enable_config_discovery, :kind_of => [TrueClass, FalseClass], :required => true, :default => true
property :required_contact_point_nr, :kind_of => Integer, :required => true, :default => 2

property :https_port, :kind_of => Integer, :required => true, :default => 9443
property :https_address, :kind_of => String, :required => true, :default => "0.0.0.0"

property :enable_ssl, :kind_of => [TrueClass, FalseClass], :default => false
property :ssl_cert, :kind_of => String
property :ssl_key, :kind_of => String
property :ssl_chain, :kind_of => String
property :jks_file, :kind_of => String, :default => lazy {|a| "#{a.name}.jks"}
property :jks_password, :kind_of => String, :default => lazy {|a| a.name}
property :security_properties_file, :kind_of => String, :default => lazy {|a| "#{a.name}.security.properties"}
property :security_properties, :kind_of => Hash, :default => {
    'jdk.tls.disabledAlgorithms' => 'EC keySize < 160, RSA keySize < 2048, DSA keySize < 2048',
    'jdk.certpath.disabledAlgorithms' => 'MD2, MD4, MD5, EC keySize < 160, RSA keySize < 2048, DSA keySize < 2048'
}

property :domains, :kind_of => Array, :required => true, :default => ['localhost']
property :app_env, :kind_of => Object, :required => true, :default => {}
property :env_file, :kind_of => String, :default => lazy {|a| "#{a.name}.env"}

property :version, :kind_of => String, :required => true
property :source_url, :kind_of => String, :required => true
property :source_checksum, :kind_of => String, :required => false, :default => nil
property :source_user, :kind_of => String, :required => false, :default => nil
property :source_password, :kind_of => String, :required => false, :default => nil

property :keep_releases, :kind_of => Integer, :required => true, :default => 3
property :force_deploy, :kind_of => [TrueClass, FalseClass], :required => true, :default => true

property :autoconfigure_memory, :kind_of => [TrueClass, FalseClass], :required => true, :default => true
property :xmx_ratio, :kind_of => Float, :required => true, :default => 1.0
property :xmx_min, :kind_of => Integer, :required => true, :default => 128
property :xmx_leftover_min, :kind_of => Integer, :required => true, :default => 256
property :xms_xmx_ratio, :kind_of => Float, :required => true, :default => 0.25

property :config_file, :kind_of => String, :default => lazy {|a| "#{a.name}.conf"}
property :config_template_cookbook, :kind_of => String, :required => false, :default => 'application_play'
property :config_template_source, :kind_of => String, :required => false, :default => 'application.conf.erb'
property :settings, :kind_of => Hash, :required => true, :default => {}
property :java_settings, :kind_of => String, :required => true, :default => '-J-server' +
    '-Dsun.security.ssl.allowUnsafeRenegotiation=false ' +
    '-Djdk.tls.ephemeralDHKeySize=2048 ' +
    '-Djdk.tls.rejectClientInitiatedRenegotiation=true '