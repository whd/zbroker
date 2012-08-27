require "yaml"
require "optparse"

module ZBroker::Config
  def self.load_config
    file = '/etc/zbroker/zbroker.yml'
    port = nil
    optparse = OptionParser.new do |o|
      o.on('-f', '--config-file FILE',
           'location of the config file (default /etc/zbroker/zbroker.yaml)') do |arg|
        file = arg
      end
      o.on('-p', '--port PORT', 'port to bind to') do |arg|
        port = arg.to_i
      end
    end
    optparse.parse!

    unless File.exists?(file) && File.readable?(file)
      abort "file #{file} not found or not readable (-f)"
    end

    config = YAML::load_file(file) rescue nil
    abort "failed to parse config file #{file}" unless config
    abort "no environments found in #{file}" unless config['environments']
    abort "no lower limit (capacity) found in #{file}" unless config['capacity']
    # 0 means don't cache results
    config['cache_expiry'] ||= 500

    config['port'] = port if port
    config
  end
end
