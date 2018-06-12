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
    'play.evolutions.autoApply' => 'true',
    'ssl-config.enabledCipherSuites' => '[
        "TLS_DHE_RSA_WITH_AES_128_GCM_SHA256",
        "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
        "TLS_DHE_RSA_WITH_AES_256_GCM_SHA384",
        "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    ]',
    'ssl-config.protocol' => 'TLSv1.2',
}

default['application_play']['opsworks']['default_java_settings'] = '-J-server ' +
    '-Dsun.security.ssl.allowUnsafeRenegotiation=false ' +
    '-Djdk.tls.ephemeralDHKeySize=2048 ' +
    '-Djdk.tls.rejectClientInitiatedRenegotiation=true '

default['application_play']['opsworks']['security_properties'] = {
    'jdk.tls.disabledAlgorithms' => 'EC keySize < 160, RSA keySize < 2048, DSA keySize < 2048',
    'jdk.certpath.disabledAlgorithms' => 'MD2, MD4, MD5, EC keySize < 160, RSA keySize < 2048, DSA keySize < 2048'
}
