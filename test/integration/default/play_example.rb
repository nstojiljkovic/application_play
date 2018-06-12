# # encoding: utf-8

# Inspec test for recipe application_play::opsworks_deploy

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('play_example') do
  it {should exist}
end

describe service('play_example') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# Sleep a bit until the service starts up
sleep(5)

describe port(9123) do
  it {should be_listening}
end

describe http('http://localhost:9123') do
  its('status') {should cmp 200}
  its('body') {should match /Your new application is ready/}
  its('headers.Content-Type') {should cmp 'text/html; charset=UTF-8'}
end

describe http('http://127.0.0.1:9123') do
  its('status') {should cmp 400}
  its('body') {should match /Host not allowed/}
  its('headers.Content-Type') {should cmp 'text/html; charset=UTF-8'}
end