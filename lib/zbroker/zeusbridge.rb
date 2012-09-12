require "zeus-api"
require "resolv"
require "zbroker/lcs"
require "zbroker/agent"

class ZBroker::ZeusBridge
  include ZBroker::LCS

  def initialize (config)
    @agents = {} # environment => Agent
    @resolver = Resolv::DNS.new
    @environments = config['environments']
    @min_capacity = config['capacity']
    @cache_expiry = config['cache_expiry']
  end

  def find_environment (name)
    STDERR.puts "find environment for #{name}"
    z = @environments.select do |k, v|
      k == lcs(k, name)
    end.max {|k, v| k.length <=> v.length}
    STDERR.puts "environment found: #{z.inspect}"
    z
  end

  def zeus_connection_error
    {'status' => 'request_failed', 'reason' => 'zeus_connection_error'}
  end

  def zeus_environment_error
    {'status' => 'request_failed', 'reason' => 'no_environment_found'}
  end

  def quietly
    null = IO::NULL rescue '/dev/null'
    stderr = $stderr.dup
    STDERR.reopen(null)
    begin
      ret = yield
    ensure
      STDERR.reopen stderr
    end
    ret
  end

  def process (request)
    begin
      hostname = @resolver.getname(request.ip).to_s
      STDERR.puts hostname

      env = find_environment(hostname)
      return [zeus_environment_error] unless env

      envname = env.first
      unless @agents[envname]
        # populate the pool table
        @agents[envname] = quietly do
          ZBroker::Agent.new(env)
        end
      end

      agent = @agents[envname]
      if (Time.now - agent.timestamp) > @cache_expiry
        quietly {agent.update}
      end

      node = "#{request.ip}:#{request.port}"

      ret = quietly do
        if request.command == 'remove'
          agent.drain(node, @min_capacity, (request.limit rescue nil))
        elsif request.command == 'add'
          agent.add(node)
        end
      end

      ret.each {|r| r['node'] = node}
      ret
    rescue Exception => err
      STDERR.puts err
      STDERR.puts err.backtrace
      res = zeus_connection_error
      res['exception'] = err.to_s
      res['node'] = node if node
      return [res]
    end
  end
end
