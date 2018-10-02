# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require 'resque/server'
require 'resque_scheduler'
require 'resque_scheduler/server'
require 'sidekiq/web'

Resque::Server.use Rack::Auth::Basic do |username, password|
   username == 'impact' && password == (ENV['ADMIN_PASSWORD'] || rand)
end

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  username == 'impact' && password == (ENV['ADMIN_PASSWORD'] || rand)
end

run Rack::URLMap.new \
  "/"       => ImpactDialing::Application,
  "/resque" => Resque::Server.new,
  "/sidekiq" => Sidekiq::Web
