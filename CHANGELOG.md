# application_play CHANGELOG

## 0.1.6

Add support for deploying Akka cluster and remote (with or without Akka management).

## 0.1.5

Add `service_settings` parameter to the `application_play` resource for overriding systemd service `[Settings]`.

## 0.1.4

Prevent Chef from backing up release archives as they are handled by the `application_play` resource.

## 0.1.3

Added HTTPS support.

## 0.1.2

Updated opsworks_deploy recipe to deploy only applications denoted by `aws_opsworks_command` data bag items.

## 0.1.1

Added testing and contributing information.

## 0.1.0

Initial release.
