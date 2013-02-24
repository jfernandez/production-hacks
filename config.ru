require 'builder'
require 'rack-rewrite'
require 'rdiscount'
require 'toto'

if Toto.env == 'development'
  require 'new_relic/control'
  NewRelic::Control.instance.init_plugin 'developer_mode' => true,
                                         :env => Toto.env

  require 'new_relic/rack/developer_mode'
  use NewRelic::Rack::DeveloperMode
else
  require 'newrelic_rpm'
end

require 'new_relic/agent/instrumentation/rack'
require 'new_relic/agent/instrumentation/controller_instrumentation'

Toto::Server.class_eval do
  include NewRelic::Agent::Instrumentation::Rack
end

[ Toto::Archives, Toto::Article, Toto::Repo ].each do |toto_klass|
  toto_klass.class_eval do
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    add_transaction_tracer :to_html
  end
end

unless Object.const_defined?(:DOMAIN)
  DOMAIN = 'www.productionhacks.com'
end

# Rack config
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico', '/robots.txt'], :root => 'public'
use Rack::CommonLogger

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
::NewRelic::Agent.manual_start :app_name => 'productionhacks.com'