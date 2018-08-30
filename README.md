# application_play

A [Chef](https://www.chef.io/) cookbook to deploy Play framework applications.

## Requirements

Chef 12.1 or newer is required.

## Resources

### `application_play`

The `application_play` resource installs a Play framework application from packaged zip tarball (created using `sbt universal:packageZipTarball` 
task or [`sbt-release`](https://github.com/sbt/sbt-release) plugin). The application is configured as a 
[systemd](https://www.freedesktop.org/wiki/Software/systemd/) service. This resource is using [`application`](https://github.com/poise/application) cookbook
version 5 as a base.

The Play framework application is deployed using a pseudo-Capistrano folder structure but without using the obsolete Chef [`deploy`](https://docs.chef.io/resource_deploy.html) resource
or [`deploy_resource`](https://supermarket.chef.io/cookbooks/deploy_resource) from Supermarket. The implemented logic is way simpler than in the old `deploy` resource.
There are still `current` and `releases` folders but without a rollback action. Rollback is to be done by simply reverting the version to be installed. The fact that we
keep preconfigured number of releases will allow fast rollbacks in case of any error. Important thing to note is that there is no automated rollback on deployment 
error (by design). Consider yourself warned if you are going to use this on a single server.

Sample usage:

```ruby
application 'play_example' do
  owner 'play_example'
  group 'play_example'
  path '/home/play_example'

  play 'play_example' do
    app_env({
      'APPLICATION_SECRET' => "QCY?tAnfk?aZ?iwrNwnxIlR6CTf:G3gf:90Latabg@5241AB`R5W:1uDFN];Ik@n"
    })
    domains(%w(localhost 127.0.0.1))
    settings({
      'play.evolutions.autoApply' => 'true'
    })
    port 9000
    address '0.0.0.0'

    version '1.0-SNAPSHOT'
    source_url 'https://github.com/nstojiljkovic/application_play/raw/artifacts/play-2.6/play-scala-starter-example-1.0-SNAPSHOT.tgz'
    source_user nil
    source_password nil
    source_checksum 'ae56a1f97f32aae73de25de599d7ce45191eee46b900205e50d1082bf529b0ae'

    keep_releases 3
    force_deploy true

    autoconfigure_memory true
    xms_xmx_ratio 0.25
    xmx_ratio 1.0
    xmx_min 128
    xmx_leftover_min 256
  end

  action :deploy
end
```

#### Actions

* `:deploy` – Deploy application, create, enable and start the service. *(default)*
* `:start` – Start the service.
* `:stop` – Stop the service.
* `:restart` – Stop and then start the service.

#### Properties

* `name` – Application name. *(set on the parent `application` resource!)*
* `path` – Path to deploy the application to. *(set on the parent `application` resource!)*
* `group` – System group to deploy the application as. *(set on the parent `application` resource!)*
* `owner` – System user to deploy the application as. *(set on the parent `application` resource!)*
* `service_name` – Name of the service to create. *(default: `name`)*
* `service_description` – Description of the service to create. *(default: `"#{name} service"`)*
* `systemd_settings` – systemd service override. May include `Unit`, `Service` etc. keys as per [systemd_unit resource documentation](https://docs.chef.io/resource_systemd_unit.html). *(default: `{}`)*
* `port` – Port on which the application should listen to. *(default: `9000`)*
* `address` – Address on which the application should listen to. *(default: `'0.0.0.0'`)*
* `actor_system_name` - Actor system name. *(default: `'application'`)*
* `actor_provider` - Actor provider. *(default: `'local'`, other supported options are `'cluster''` and `'remote''`)*
* `contact_points` - Active contact points (including self) as a simple list of IP addresses. It is assumed that all nodes will share the same ports configuration. *(default: `'[]'`)*
* `management_port` - Akka management port. *(default: `8558`)*
* `management_hostname` - Akka management hostname. *(default: `nil`)*
* `remote_port` - Akka remote port. *(default: `2552`)*
* `remote_hostname` - Akka remote hostname. *(default: `nil`)*
* `enable_config_discovery` - Should Akka management config discovery be used. If set to false, `contact_points` will be configured as plain seed nodes (without requiring Akka management to be deployed with the application). *(default: `true`)*
* `required_contact_point_nr` - Required contact points number. *(default: `2`)*
* `enable_ssl` – Enable HTTPS endpoint. All HTTP traffic will be redirected to HTTPS. *(default: `false`)*
* `ssl_cert` – SSL certificate. *(default: `nil`)*
* `ssl_key` – SSL private key (without password). *(default: `nil`)*
* `ssl_chain` – SSL certificate chain. *(default: `nil`)*
* `jks_file` – Java KeyStore (JKS) file. *(default: `"#{name}.jks"`)*
* `jks_password` – JKS password. *(default: `"#{name}"`)*
* `https_port` – HTTPS port on which the application should listen to (if `enable_ssl` is set to `true`). *(default: `9443`)*
* `https_address` – Address on which the application should listen to (HTTPS endpoint, if `enable_ssl` is set to `true`). *(default: `'0.0.0.0'`)*
* `security_properties_file` – Java security properties file. *(default: `"#{name}.security.properties"`)*
* `security_properties` – Java security properties. *(default: `"#{'jdk.tls.disabledAlgorithms' => 'EC keySize < 160, RSA keySize < 2048, DSA keySize < 2048', 'jdk.certpath.disabledAlgorithms' => 'MD2, MD4, MD5, EC keySize < 160, RSA keySize < 2048, DSA keySize < 2048'}"`)*
* `domains` – List of domains which should be configured as allowed hosts. *(default: `['localhost']`)*
* `app_env` – Environment variables hash. *(default: {})*
* `env_file` – Name of the `systemd` `EnvironmentFile` file (which will be populated by default with `app_env` hash). *(default: `"#{name}.env"`)*
* `version` – Application version (release). *(required)*
* `source_url` – Application source URL. *(required)*
* `source_checksum` – Application source SHA-256 checksum. Setting it recommended for two purposes: verification and prevention of double downloads. *(default: `nil`)*
* `source_user` – HTTP user for application source download. *(default: `nil`)*
* `source_password` – HTTP password for application source download. *(default: `nil`)*
* `keep_releases` – Number of releases which should be kept on the server. Allows fast rollbacks. Set to 0 to keep all. *(default: `3`)*
* `force_deploy` – Denotes if deployment should be forced: re-download and re-extract artifact even if release exist. *(default: `true`)*
* `autoconfigure_memory` - Denotes if Java XMS and XMX properties should be preconfigured for the service. *(default: `true`)*
* `xmx_ratio` - Percentage of system memory which should be allocated for XMX. Please note that this is affected later in the calculation by `xmx_min` and `xmx_leftover_min`. *(default: `1.0`)*
* `xmx_min` -  Minimal allowed value of XMX (in MB). *(default: `128`)*
* `xmx_leftover_min` - Minimal amount of memory (in MB) which should be left for other system processes. Please note that `xmx_min` has priority. *(default: `256`)*
* `xms_xmx_ratio` - What amount of XMX should be set to XMS setting. *(default: `0.25`)*
* `config_file` - Name of the production application.conf file which is shared for all releases (and updated on deployment). It includes application's embedded `application.conf` and overrides it afterwards. *(default: `"#{name}.conf"`)*
* `config_template_cookbook` - Cookbook where the template `config_template_source` for the `config_file` is located. *(default: `application_play`)*
* `config_template_source` - Template for the `config_file`. *(default: `application.conf.erb`)*
* `settings` - Production configuration hash (populated in `config_file`). *(default: `{}`)*
* `java_settings` - Java settings to apply in the `systemd` service. *(default: `-J-server -Dsun.security.ssl.allowUnsafeRenegotiation=false -Djdk.tls.ephemeralDHKeySize=2048 -Djdk.tls.rejectClientInitiatedRenegotiation=true`)*

## Recipes

### OpsWorks

Cookbook has few recipes prepared for usage with [AWS OpsWorks](https://aws.amazon.com/opsworks/):

* `opsworks_configure`
* `opsworks_deploy`
* `opsworks_setup`
* `opsworks_shutdown`
* `opsworks_undeploy`

Each of these should be configured in the run list for a corresponding OpsWorks layer lifecycle event.

OpsWorks application supports the following environment variables:

* `PLAY_APP` - Signals the `opsworks_deploy` to deploy the application. *(required)*
* `APP_USER_UID` - Recommended, signals the `opsworks_deploy` to automatically create user and group for the application. Configuring the app user uid here comes handy if you need to have the same user uid across your nodes.
* `HTTP_PORT` - Port on which the application should listen to.
* `HTTP_ADDRESS` - Address on which the application should listen to.
* `HTTPS_PORT` - HTTPS port on which the application should listen to (if SSL is enabled).
* `HTTPS_ADDRESS` -  Address on which the application should listen to (HTTPS endpoint, if SSL is enabled).
* `APPLICATION_SECRET` - Application secret. It is obviously recommended to configure it as protected value in OpsWorks console.

You can of course use any other environment variable, they will be exposed to your application and you can even use them in the default `application.conf`. That's how the secret is passed in the default application configuration file:

```ini
play.http.secret.key=${?APPLICATION_SECRET}
```

Don't forget to take a look at the attributes `opsworks.rb` file to see the default values which are passed to the `application_play` resource.
