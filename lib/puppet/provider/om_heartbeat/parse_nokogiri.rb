Puppet::Type.type(:om_heartbeat).provide(:parse_nokogiri) do

  confine :feature => :nokogiri
  confine :exists => '/var/opt/OV/share/hbmsi/HBConfig.xml'

  def self.configfile
    '/var/opt/OV/share/hbmsi/HBConfig.xml'
  end

  def self.document
    unless @document
      File.open(self.configfile,'r') do |f|
        @document = Nokogiri::XML::Document.parse(f, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS)
      end
    end
    @document
  end

  def self.initvars
    @document = nil
    super
  end

  def self.flush
    if @document
      File.open(self.configfile,'w') do |f|
        @document.write_xml_to(f)
      end
    end
  end

  def self.instances
    heartbeats = {}

    self.document.xpath('/OVOHeartBeat/Hosts/Host').each do |node|
      if node.has_attribute?('name')
        fqdn = node.attributes['name'].content
        heartbeats[fqdn] = {:name => fqdn, :ensure => :present,  :heartbeats => []}
      else
        warning "Found host element with no name attribute"
      end
    end

    self.document.xpath('/OVOHeartBeat/HeartBeats/HeartBeat').each do |heartbeat|
      if heartbeat.has_attribute?('name')
        hb = heartbeat.attributes['name'].content
        heartbeat.children.each do |child|
          next unless child.name == 'Rule'
          if child.has_attribute? 'host'
            fqdn = child.attributes['host'].content
            if heartbeats.include?(fqdn)
              if heartbeats[fqdn][:heartbeats].include? hb
                warning "Host #{fqdn} already assigned to heartbeat #{hb}"
              else
                heartbeats[fqdn][:heartbeats] << hb
              end
            else
              warning "Host #{fqdn} is assigned to heartbeat #{hb} but does not appear in host list. Ignore this assignment"
            end
          else
            warning "Found rule inside heartbeat #{hb} with no host attribute"
          end
        end
      else
        warning "Found heartbeat with no name attribute. Heartbeat is ignored"
      end
    end

    instances = []
    heartbeats.each do |k,h|
      h[:heartbeats] = h[:heartbeats].join(',')
      instances << new(h)
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

  def create
    doc = self.class.document
    if parent = doc.at_xpath('/OVOHeartBeat/Hosts')
      child = Nokogiri::XML::Node.new('Host',doc)
      child['name'] = resource[:name]
      parent.add_child(child)
    else
      raise Puppet::Error, "Unable to add node #{resource[:name]} to host list. Element /OVOHeartBeat/Hosts not found"
    end

    if resource[:heartbeats] and !resource[:heartbeats].empty?
      resource[:heartbeats].split(',').each do |hb|
        if parent = doc.at_xpath("/OVOHeartBeat/HeartBeats/HeartBeat[@name='#{hb}']")
          child = Nokogiri::XML::Node.new('Rule',doc)
          child['host'] = resource[:name]
          parent.add_child(child)
        else
          raise Puppet::Error, "Unable to assign node #{resource[:name]} to heartbeat #{hb}. Heartbeat not found"
        end
      end
    end
  end

  def destroy
    doc = self.class.document
    if @property_hash[:heartbeats] and !@property_hash[:heartbeats].empty?
      @property_hash[:heartbeats].split(',').each do |hb|
        child = doc.at_xpath("/OVOHeartBeat/HeartBeats/HeartBeat[@name='#{hb}']/Rule[@host='#{@property_hash[:name]}']")
        if child
          child.remove
        else
          raise Puppet::Error, "Unable to deassign node #{@property_hash[:name]} from heartbeat #{hb} because the xml node was not found"
        end
      end
    end
    child = doc.at_xpath("/OVOHeartBeat/Hosts/Host[@name='#{@property_hash[:name]}']")
    if child
      child.remove
    else
      raise Puppet::Error, "Unable to remove node #{@property_hash[:name]} from node list because the xml node was not found"
    end
  end

  def exists?
    get(:ensure) != :absent
  end

  def heartbeats
    get(:heartbeats)
  end

  def heartbeats=(new_value)
    doc = self.class.document
    old = (@property_hash[:heartbeats] || "").split(',')
    new = new_value.split(',')
    (new - old).each do |hb|
      if parent = doc.at_xpath("/OVOHeartBeat/HeartBeats/HeartBeat[@name='#{hb}']")
        child = Nokogiri::XML::Node.new('Rule',doc)
        child['host'] = resource[:name]
        parent.add_child(child)
      else
        raise Puppet::Error, "Unable to assign node #{resource[:name]} to heartbeat #{hb}. Heartbeat not found"
      end
    end
    (old-new).each do |hb|
      child = doc.at_xpath("/OVOHeartBeat/HeartBeats/HeartBeat[@name='#{hb}']/Rule[@host='#{@property_hash[:name]}']")
      if child
        child.remove
      else
        raise Puppet::Error, "Unable to deassign node #{@property_hash[:name]} from heartbeat #{hb} because the xml node was not found"
      end
    end
  end

  def flush
    self.class.flush
  end

end
