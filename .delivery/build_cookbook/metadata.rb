name 'build_cookbook'
maintainer 'Nikola Stojiljkovic'
maintainer_email 'no-reply@nikolastojiljkovic.com'
license 'all_rights'
version '0.1.0'
chef_version '>= 12.14' if respond_to?(:chef_version)

depends 'delivery-truck'
