# # encoding: utf-8

# Inspec test for recipe application_play::opsworks_deploy

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('play_example_https') do
  it {should exist}
end

describe service('play_example_https') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# Sleep a bit until the service starts up
sleep(10)

describe port(80) do
  it {should be_listening}
end

describe port(443) do
  it {should be_listening}
end

describe http('http://localhost') do
  its('status') {should cmp 308}
  its('headers.Location') {should cmp 'https://localhost/'}
end

describe http('http://127.0.0.1') do
  its('status') {should cmp 400}
  its('body') {should match /Host not allowed/}
  its('headers.Content-Type') {should cmp 'text/html; charset=UTF-8'}
end

describe http('https://localhost', ssl_verify: false) do
  its('status') {should cmp 200}
  its('body') {should match /Your new application is ready/}
  its('headers.Content-Type') {should cmp 'text/html; charset=UTF-8'}
end

describe http('https://127.0.0.1', ssl_verify: false) do
  its('status') {should cmp 400}
  its('body') {should match /Host not allowed/}
  its('headers.Content-Type') {should cmp 'text/html; charset=UTF-8'}
end

describe ssl(port: 80) do
  it { should_not be_enabled }
end

# describe ssl(port: 443) do
#    it { should be_enabled }
# end
