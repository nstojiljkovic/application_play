name 'application_play'
maintainer 'Nikola Stojiljkovic'
maintainer_email 'no-reply@nikolastojiljkovic.com'
license 'Apache-2.0'
description 'Installs/Configures Play application'
long_description 'Installs/Configures Play application'
version '0.1.1'
supports ['centos', 'ubuntu']
chef_version '>= 12.14' if respond_to?(:chef_version)

depends 'application', '~> 5.2.0'
depends 'java_se', '~> 10.0.1'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
issues_url 'https://github.com/nstojiljkovic/application_play/issues'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
source_url 'https://github.com/nstojiljkovic/application_play'
