require 'toto'
require 'rack-rewrite'

# Rack config
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico'], :root => 'public'
use Rack::CommonLogger

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
end

use Rack::Rewrite do
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