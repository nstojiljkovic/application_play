include Poise(parent: :application)

actions(:deploy, :start, :stop, :restart)
default_action :deploy

property :service_name, :kind_of => String, :required => false, :default => lazy {|a| a.name}
property :service_description, :kind_of => String, :required => false, :default => lazy {|a| "#{a.name} service"}

property :port, :kind_of => Integer, :required => true, :default => 9000
property :address, :kind_of => String, :required => true, :default => "0.0.0.0"

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
property :java_settings, :kind_of => String, :required => true, :default => '-J-server'