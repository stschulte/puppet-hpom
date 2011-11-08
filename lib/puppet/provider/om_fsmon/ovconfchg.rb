Puppet::Type.type(:om_fsmon).provide(:ovconfchg) do

  desc "Uses the ovconfchg command to change the agent config
    and set the thresholds that the monitor policy will take
    into account"

  commands :ovconfchg => '/opt/OV/bin/ovconfchg'
  commands :ovconfget => '/opt/OV/bin/ovconfget'

  self::THRESHOLDS = [ :warning, :minor, :major, :critical ]
  self::OM_PROPERTY = {
    :warning  => 'SpaceUtilWarningThreshold',
    :minor    => 'SpaceUtilMinorThreshold',
    :major    => 'SpaceUtilMajorThreshold',
    :critical => 'SpaceUtilCriticalThreshold'
  }
  self::DEFAULT_THRESHOLD = {
    :warning  => '80',
    :minor    => '85',
    :major    => '90',
    :critical => '95'
  }

  mk_resource_methods

  def self.initvars
    @thresholds = {}
  end

  def self.instances
    hash = {}         # used to build the provider array. Key is directory
    @thresholds = {}  # used to store current om config. Key is the property
    self::OM_PROPERTY.each do |property,om_property|
      @thresholds[property] = {}
      fields = ovconfget('eaagt',om_property).chomp.split(',')
      if fields.empty?
        debug "#{om_property} in section eaagt not yet present"
      else
        fields[1..-1].each do |assignment|
          if match = /\s*(.*)\s*=\s*(\d+)\s*/.match(assignment)
            directory = match.captures[0]
            threshold = match.captures[1]
            @thresholds[property][directory] = threshold
            unless hash.include? directory
              hash[directory] = {:name => directory}
            end
            hash[directory][property] = threshold
          else
            warn "Unable to interpret assignment #{assignment} of threshold #{om_property}"
          end
        end
      end
    end
    instances = []
    hash.each do |provider_name,provider_hash|
      instances << new(provider_hash)
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

  # when we flush changes and write the new agent config we have to
  # know all the other thresholds. So just pass the changed record
  # and modify the in-memory represenetation of the agent config which
  # is stored in the @thresholds class variable. This hash is organized by
  # property (warning,minor,major,critical). Each value is a hash of directories
  # and the value of the current threshold (warning, minor, major or critical)
  def self.flush(record)
    args = [ '-ns', 'eaagt' ]
    self::THRESHOLDS.each do |threshold|
      if record[threshold] == :absent or record[threshold].nil?
        @thresholds[threshold].delete(record[:name])
      else
        @thresholds[threshold][record[:name]] = record[threshold]
      end
      args << '-set' << self::OM_PROPERTY[threshold]
      args <<  "#{self::DEFAULT_THRESHOLD[threshold]},#{@thresholds[threshold].map{|k,v| "#{k}=#{v}"}.sort.join(',')}"
    end
    ovconfchg(*args)
  end

  def flush
    @property_hash[:name] ||= resource[:name]
    self.class.flush(@property_hash)
  end

end
