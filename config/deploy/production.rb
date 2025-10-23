# frozen_string_literal: true

# config/deploy/production.rb
server '24.199.71.69', user: 'zac', roles: %w[app db web]

set :ssh_options, {
  keys: ["#{ENV['HOME']}/.ssh/id_rsa"], # Specify the path to your SSH key
  forward_agent: true,
  auth_methods: %w[publickey],
  verify_host_key: :never,
  user_known_hosts_file: '/dev/null'
}
