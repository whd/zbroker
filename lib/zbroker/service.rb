# wrap PoolService with capacity limits
class ZBroker::Service < PoolService
  def initialize (endpoint, user, pass, envdata)
    super(endpoint, user, pass)

    @capacities = {}
    @timeouts = {}

    (envdata||{}).each do |k, v|
      v['pools'].each do |item|
        mincap = v['capacity'] || 1.0 # a rather conservative default
        if item.is_a?(Array)
          pool = item.first
          mincap = item.last
        else
          pool = item
        end
        STDERR.puts "pool: #{pool}"
        STDERR.puts "mincap: #{mincap}"

        @timeouts[pool] = v['timeout']
        @capacities[pool] = mincap
      end
    end
  end

  def timeout (pool)
    @timeouts[pool] rescue nil
  end

  def pool_capacity (pool)
    STDERR.puts "looking up pool capacity for #{pool}"
    STDERR.puts @capacities.inspect
    STDERR.puts "#{@capacities[pool]}"
    @capacities[pool].first rescue nil
  end
end
