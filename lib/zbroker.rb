require "sinatra/base"
require "json"
require "zbroker/version"
require "zbroker/config"
require "zbroker/request"
require "zbroker/zeusbridge"

module ZBroker
  class App < Sinatra::Base
    config = ZBroker::Config::load_config
    set :config, config
    set :bridge, ZBroker::ZeusBridge.new(config)
    set :port, config['port'] if config['port']
    set :run, true
    set :logging, true
    set :lock, Mutex.new

    before do
      settings.lock.lock
    end

    get '/zbroker/api' do
      # set up a request object
      req = Request.new(request.ip, params)
      # if the request isn't bogus, process it
      req.result ||= settings.bridge.process(req)
      # set content type
      content_type req.format
      # and serialize it
      req.serialize
    end

    after do
      settings.lock.unlock
    end
  end
end
