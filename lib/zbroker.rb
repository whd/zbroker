require "sinatra/base"
require "json"
require "zbroker/version"
require "zbroker/config"
require "zbroker/request"
require "zbroker/zeusbridge"

module ZBroker
  class App < Sinatra::Base
    set :run, false
    set :config, ZBroker::Config::load_config
    set :bridge, ZBroker::ZeusBridge.new(config)
    set :port, settings.config['port'] if settings.config['port']
    set :logging, true
    set :lock, true

    # RackBaseURI is set to /zbroker
    get '/api' do
      # set up a request object
      req = Request.new(request.ip, params)
      # if the request isn't bogus, process it
      req.result ||= settings.bridge.process(req)
      # set content type
      content_type req.format
      # and serialize it
      req.serialize
    end
  end
end
