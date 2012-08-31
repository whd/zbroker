class ZBroker::Agent
  attr_reader :timestamp

  def initialize (pool_service)
    @p = pool_service
    @pool_data = {} # pool => [active, draining]
    @lookup = {} # node => pool
    @timestamp = nil
    update
  end

  def _drain_status(pool, node)
    count = @p.connection_count(node).first
    return {'pool' => pool, 'status' => (count == 0 ? 'drained' : 'draining')}
  end

  def _no_pool
    {'status' => 'request_failed', 'reason' => 'no_pool_found'}
  end

  def drain (node, min_capacity, request_capacity=nil)
    pool = @lookup[node]
    active, draining = @pool_data[pool]
    return _no_pool unless pool
    return _drain_status(pool, node) if draining.member?(node)

    capacity = [min_capacity, (request_capacity||-1)].max

    if (cap = (active.size - 1.0) / (active.size + draining.size)) < capacity
      res = {
        'pool' => pool,
        'status' => 'request_failed',
        'reason' => 'capacity_limit',
        'minimum_capacity' => min_capacity,
        'drained_capacity' => cap
      }
      res['request_capacity'] = request_capacity if request_capacity
      return res
    else
      @p.drain_node(pool, node)
      nactive = active - [node]
      ndraining = draining + [node]
      @pool_data[pool] = [nactive, ndraining]
      return _drain_status(pool, node)
    end
  end

  def add (node)
    pool = @lookup[node]
    return _no_pool unless pool
    active, draining = @pool_data[pool]
    if draining.include?(node)
      # fixme out-of-date cache can cause this to fail
      @p.undrain_node(pool, node)
      nactive = active + [node]
      ndraining = draining - [node]
      @pool_data[pool] = [nactive, ndraining]
    end
    return {'pool' => pool, 'status' => 'added'}
  end

  def update
    @pool_data = {}
    @lookup = {}
    pools = @p.list
    pools.each do |pool|
      nodes = @p.list_nodes(pool).flatten
      nodes.each {|node| @lookup[node] = pool}
      draining = @p.list_nodes(pool, :draining).flatten
      active = nodes - draining
      @pool_data[pool] = [active, draining]
    end
    @timestamp = Time.now
  end
end
