# frozen_string_literal: true
# Capfile

require 'stringio'

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Include tasks from other gems
require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

# Load rbenv support
require 'capistrano/rbenv'

# Load bundler support
require 'capistrano/bundler'

# Load Rails specific tasks
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'

# Load Puma tasks
require 'capistrano/puma'
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

# Load custom tasks
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }