#
# Cookbook:: application_play
# Recipe:: opsworks_setup
#
# Copyright:: 2018, Nikola Stojiljkovic, All Rights Reserved.

if node['application_play']['opsworks']['install_java']
  include_recipe 'java_se::default'
end