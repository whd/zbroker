# wrap PoolService with capacity limits
class ZBroker::Service < PoolService
  def initialize (endpoint, user, pass, envdata)
    super(endpoint, user, pass)

    @services = {}
    @capacities = {}

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

        @services[pool] = mincap
      end
    end
  end

  def pool_capacity (pool)
    STDERR.puts "looking up pool capacity for #{pool}"
    STDERR.puts @services.inspect
    STDERR.puts "#{@services[pool]}"
    @services[pool] rescue nil
  end
end
