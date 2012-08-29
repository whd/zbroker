class ZBroker::Request
  attr_accessor :result

  def initialize (ip, params={})
    @result = nil
    @params = sanitize(params)
    @params['ip'] = ip
    @params['format'] ||= 'yaml'
  end

  def sanitize (params)
    missing = []
    hsh = {}
    params.each do |k, v|
      value = verify_return(k, v) || nil
      hsh[k] = value if value
    end

    ['command', 'port'].each do |p|
      missing << p unless hsh[p]
    end

    unless missing.empty?
      @result = {
        'status' => 'request_failed',
        'reason' => 'missing_parameters',
        'parameters' => missing
      }
    end
    hsh
  end

  # verify PARAM has a valid converted value and return it, or return false
  def verify_return (param, arg)
    case param
    when 'command'
      (arg == 'remove' || arg == 'add') && arg
    when 'port'
      arg =~ /\d+/ && (0..65535).include?(arg.to_i) && arg.to_i
    when 'limit'
      (0..1).include?(arg.to_f) && arg.to_f
    when 'format'
      (arg == 'json' || arg == 'yaml') && arg
    when true
      false
    end
  end

  def serialize
    @result.send("to_#{@params['format']}")
  end

  def method_missing (method, *args)
    @params[method.to_s] || super
  end
end
