source 'http://rubygems.org'

gem 'rails', '3.1.0'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'twitter-bootstrap-rails'
gem 'formtastic'
gem 'formtastic-bootstrap'
gem 'haml'
gem 'activeadmin'
gem 'meta_search', '>= 1.1.0.pre'
gem "devise_ldap_authenticatable"
gem 'thin'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

gem 'jquery-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
  gem 'rspec'
end
group :development, :test do
  gem 'sqlite3'
end
group :production do
  gem 'pg'
end
