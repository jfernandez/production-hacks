require 'rubygems'
require 'bundler'

Bundler.require

DOMAIN = 'www.productionhacks.com'

# Rack config
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico', '/robots.txt'], :root => 'public'
use Rack::CommonLogger

if ENV['RACK_ENV'] == "development"
  use Rack::ShowExceptions  
else
  ENV['APP_ROOT'] ||= File.dirname(__FILE__)
  $:.unshift "#{ENV['APP_ROOT']}/vendor/plugins/newrelic_rpm/lib"
  require 'newrelic_rpm'
  require 'new_relic/agent/instrumentation/rack'
  
  module Toto
    class Server
      include NewRelic::Agent::Instrumentation::Rack
    end
  end
end

use Rack::Rewrite do
  # Redirect to the www version of the domain
  r301 %r{.*}, "http://#{DOMAIN}$&", :if => Proc.new {|rack_env|
    rack_env['SERVER_NAME'] != DOMAIN && ENV['RACK_ENV'] != "development"
  }
  
  # 301 for tumblr
  r301 %r{/post/522050660/.*}, "/2010/04/14/rails-23-cachefu-and-memcached-sessionstore/"
end

toto = Toto::Server.new do
  set :author, "Jose Fernandez"
  set :title, "Production Hacks"
  set :url, "http://www.production-hacks.com"
  set :disqus, "production-hacks"
  set :summary, :max => 300, :delim => /~/
  # set :root,      "index"                                   # page to load on /
  # set :date,      lambda {|now| now.strftime("%d/%m/%Y") }  # date format for articles
  # set :markdown,  :smart                                    # use markdown + smart-mode
  #set :disqus,    false                                     # disqus id, or false
  # set :ext,       'txt'                                     # file extension for articles
  # set :cache,      28800                                    # cache duration, in seconds

  set :date, lambda {|now| now.strftime("%B #{now.day.ordinal} %Y") }
end

run toto
