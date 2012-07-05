Puppet::Type.type(:om_config).provide(:ovconfchg) do

  commands :ovconfchg => '/opt/OV/bin/ovconfchg'
  commands :ovconfget => '/opt/OV/bin/ovconfget'

  def self.instances
    instances = []
    current_namespace = nil
    ovconfget.each_line do |line|
      next if line =~ /^#|;/
      next if line =~ /^\s*$/
      case line.chomp!
      when  /^\[(.*)\]$/
        current_namespace = $1
      when /(\S+)\s*=\s*(.*)/
        key = $1
        value = $2
        if current_namespace
          instances << new(:name => "#{current_namespace}/#{key}", :ensure => :present, :value => value)
        else
          warning "Found key-value-pair (#{line.inspect}) but no preceding namespace. Line is ignored"
        end
      else
        warning "Unexpected line #{line.inspect}. Line is ignored"
      end
    end
    instances
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    get(:ensure) != :absent
  end

  def create
    ns, key = @resource[:name].split('/',2)
    raise Puppet::Error, "Cannot create key #{@resource[:name]} without a value" unless @resource[:value]
    ovconfchg('-ns', ns, '-set', key, @resource[:value])
  end

  def destroy
    ns, key = @resource[:name].split('/',2)
    ovconfchg('-ns', ns, '-clear', key)
  end

  def value
    get(:value)
  end

  def value=(new_value)
    ns, key = @resource[:name].split('/',2)
    ovconfchg('-ns', ns, '-set', key, new_value)
  end

end
