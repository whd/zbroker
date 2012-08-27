# -*- ruby -*-
require File.expand_path('../lib/zbroker/version', __FILE__)

Gem::Specification.new do |spec|
  files = []
  dirs = %w(lib docs)
  dirs.each do |dir|
    files += Dir["#{dir}/**/*"]
  end

  spec.name = "zbroker"
  spec.version = ZBroker::VERSION
  spec.summary = "zbroker -- zeus broker"
  spec.description = "Zeus load balancer broker"
  spec.license = "Mozilla Public License (2.0)"

  spec.add_dependency("rack")
  spec.add_dependency("sinatra")
  spec.add_dependency("json")

  spec.files = files
  spec.bindir = "bin"
  spec.executables << "zbroker"

  spec.authors = ["Wesley Dawson"]
  spec.email = ["wdawson@mozilla.com"]
end
