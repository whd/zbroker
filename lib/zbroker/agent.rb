require 'zbroker/service'

class ZBroker::Agent
  attr_reader :timestamp

  def initialize (environment)
    STDERR.puts 'initializing environment'
    STDERR.puts environment.inspect
    @p = {} # endpoint => poolservice
    @envname = environment.first
    @endpoints = []
    @pool_data = {} # [endpoint, pool] => [active, draining]
    @lookup = Hash.new {Array.new} # [endpoint, node] => list of pools
    @timestamp = nil

    endpoints = environment.last
    user = 'apionly'

    endpoints.each do |name, creds|
      @endpoints << name
      STDERR.puts "endpoint #{name}, creds #{creds}"
      endpoint = creds['endpoint']
      pass = creds['pass']
      services = creds['services']
      @p[name] = ZBroker::Service.new(endpoint, user, pass, services)
    end
    update
  end

  def _drain_status(endpoint, pool, node)
    count = @p[endpoint].connection_count(node).first
    return {
      'endpoint' => "#{@envname}:#{endpoint}",
      'pool' => pool,
      'status' => (count == 0 ? 'drained' : 'draining')
    }
  end

  def _no_pool
    [{'status' => 'request_failed', 'reason' => 'no_pool_found'}]
  end

  # return list of [endpoint, pools]
  def lookup (node)
    @endpoints.map do |name|
      [name, @lookup[[name, node]]]
    end.select {|x| !x.last.empty?}.to_a
  end

  def drain (node, min_capacity, request_capacity=nil)
    STDERR.puts "draining #{node}"
    pools = lookup(node)
    return _no_pool if pools.empty?
    STDERR.puts "found node in pools #{pools.inspect}"
    res = []

    pools.each do |endpoint, pools2|
      pools2.each do |pool|
        service = @p[endpoint]
        # this call shouldn't fail, in theory
        min_capacity = service.pool_capacity(pool) || min_capacity
        STDERR.puts "min_capacity: #{min_capacity}"
        STDERR.puts "endpoint #{endpoint}, pool #{pool}"
        active, draining = @pool_data[[endpoint, pool]]

        if draining.member?(node)
          res << _drain_status(endpoint, pool, node)
          next
        end

        capacity = [min_capacity, (request_capacity||-1)].max

        if (cap = (active.size - 1.0) / (active.size + draining.size)) < capacity
          r = {
            'endpoint' => "#{@envname}:#{endpoint}",
            'pool' => pool,
            'status' => 'request_failed',
            'reason' => 'capacity_limit',
            'minimum_capacity' => min_capacity,
            'drained_capacity' => cap
          }
          r['request_capacity'] = request_capacity if request_capacity
          res << r
        else
          service.drain_node(pool, node)
          nactive = active - [node]
          ndraining = draining + [node]
          @pool_data[[endpoint, pool]] = [nactive, ndraining]
          res << _drain_status(endpoint, pool, node)
        end
      end
    end
    return res
  end

  def add (node)
    res = []
    pools = lookup node
    STDERR.puts node
    STDERR.puts pools
    return _no_pool if pools.empty?
    pools.each do |endpoint, pools2|
      pools2.each do |pool|
        active, draining = @pool_data[[endpoint, pool]]
        if draining.include?(node)
          # fixme out-of-date cache can cause this to fail
          service = @p[endpoint]
          service.undrain_node(pool, node)
          nactive = active + [node]
          ndraining = draining - [node]
          @pool_data[[endpoint, pool]] = [nactive, ndraining]
        end
        res << {
          'endpoint' => "#{@envname}:#{endpoint}",
          'pool' => pool,
          'status' => 'added'
        }
      end
    end
    return res
  end

  def update
    @pool_data = {} # [endpoint, pool] => [active, draining]
    @lookup = Hash.new {Array.new} # [endpoint, node] => list of pools
    @timestamp = nil

    @p.each do |endpoint, service|
      pools = service.list
      pools.each do |pool|
        nodes = service.list_nodes(pool).flatten
        nodes.each {|node| @lookup[[endpoint, node]] += [pool]}
        draining = service.list_nodes(pool, :draining).flatten
        active = nodes - draining
        @pool_data[[endpoint, pool]] = [active, draining]
      end
    end
    @timestamp = Time.now
  end
end
