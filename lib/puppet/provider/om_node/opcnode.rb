Puppet::Type.type(:om_node).provide(:opcnode) do
  desc "Uses the opcnode command to manage nodes"

  self::NODEHELPER = File.expand_path(File.join(File.dirname(__FILE__),"opcnodehelper.pl"))

  commands :opcnode => '/opt/OV/bin/OpC/utils/opcnode'

  commands :nodehelper => self::NODEHELPER
  confine :exists => '/opt/OV/nonOV/perl/a/bin/perl'

  [:label, :ipaddress, :network_type, :machine_type, :communication_type, :node_type, :dynamic_ip, :layout_groups, :node_groups].each do |property|
    define_method(property) do
      @property_hash[property] || :absent
    end
  end

  def self.instances
    nodes = []
    node = {}
    property = nil
    nodehelper.each_line do |line|
      case line.chomp
      when /^(\S+)$/
        # Start of new definition
        if node.include? :name
          node[:ensure] = :present
          nodes << new(node)
          node = {}
        end
        property = :name
        propertyvalue = $1
      when /^\s+(\S+)\s*:\s*(.*)$/
        property = $1.intern
        propertyvalue = $2
      when /^\s+(.*)/
        propertyvalue = $1
      else
        raise Puppet::Error, "Unexpected line #{line.inspect} while running opcnodehelper"
      end

      case property
      when :node_groups
        if propertyvalue == '(none)'
          node[property] = ''
        else
          node[property] ||= ''
          node[property] = node[property].split(',').push(propertyvalue).join(',')
        end
      when :layout_groups
        if propertyvalue == '(none)'
          node[property] = {}
        else
          node[property] ||= {}
          if match = %r{/([^/]*)/(.*)}.match(propertyvalue)
            node[property][match.captures[0].intern] = match.captures[1]
          else
            node[property][:NodeBank] = propertyvalue
          end
        end
      when :network_type, :machine_type, :communication_type, :node_type, :dynamic_ip
         node[property] = propertyvalue.intern
      else
         node[property] = propertyvalue
      end
    end

    # Store the very last node (if there were any)
    if node.include? :name
      node[:ensure] = :present
      nodes << new(node)
    end

    nodes
  end

  def self.prefetch(ovonodes)
    instances.each do |prov|
      if ovonode = ovonodes[prov.name]
        ovonode.provider = prov
      end
    end
  end

  def create
    args = ['-add_node']
    args << "node_name=#{resource[:name]}"
    args << "node_label=#{resource[:label]}" if resource[:label]
    args << "ip_addr=#{resource[:ipaddress]}" if resource[:ipaddress]
    args << "dynamic_ip=#{resource[:dynamic_ip]}" if resource[:dynamic_ip]
    args << "mach_type=#{resource[:machine_type]}" if resource[:machine_type]
    args << "net_type=#{resource[:network_type]}" if resource[:network_type]
    args << "comm_type=#{resource[:communication_type]}" if resource[:communication_type]
    args << "node_type=#{resource[:node_type]}" if resource[:node_type]
    unless resource[:node_groups].nil? or resource[:node_groups].empty?
      args << "group_name=#{resource[:node_groups].split(',').first}"
    else
      raise Puppet::Error, "Cannot create an ovo_node with no node_groups set"
    end

    opcnode(*args)

    # add to all hierarchies
    if resource[:layout_groups]
      resource[:layout_groups].each do |hierarchy,group|
        args = ['-move_nodes']
        args << "node_list=#{resource[:name]}"
        args << "node_hier=#{hierarchy}"
        args << "layout_group=#{group}"
        args << "net_type=#{resource[:network_type]}" if resource[:network_type]
        opcnode(*args)
      end
    end

    # add to remaining node_groups
    if resource[:node_groups] and !resource[:node_groups].empty?
      resource[:node_groups].split(',')[1..-1].each do |group|
        debug "Assign #{resource[:name]} to remaining group #{group}"
        args = ['-assign_node']
        args << "node_name=#{resource[:name]}"
        args << "group_name=#{group}"
        args << "net_type=#{resource[:network_type]}" if resource[:network_type]
        opcnode(*args)
      end
    end

  end

  def exists?
    get(:ensure) != :absent
  end

  def destroy
    args = ['-del_node']
    args << "node_name=#{resource[:name]}"
    args << "net_type=#{@property_hash[:network_type]}" if @property_hash.include? :network_type

    opcnode(*args)
  end

  def dynamic_ip=(new_value)
    args = ['-chg_iptype']
    args << "node_name=#{resource[:name]}"
    args << "dynamic_ip=#{new_value}"

    opcnode(*args)
  end

  def communication_type=(new_value)
    args = ['-chg_commtype']
    args << "node_name=#{resource[:name]}"
    args << "net_type=#{@property_hash[:network_type]}" if @property_hash.include? :network_type
    args << "comm_type=#{new_value}"

    opcnode(*args)
  end

  def machine_type=(new_value)
    args = ['-chg_machtype'] # doesnt support net_type
    args << "node_name=#{resource[:name]}"
    args << "mach_type=#{new_value}"

    opcnode(*args)
  end

  def node_type=(new_value)
    args = ['-chg_nodetype']
    args << "node_name=#{resource[:name]}"
    args << "net_type=#{@property_hash[:network_type]}" if @property_hash.include? :network_type
    args << "node_type=#{new_value}"

    opcnode(*args)
    @property_hash[:node_type] = new_value
  end

  def node_groups=(new_value)
    new_groups = new_value.split(',')
    old_groups = @property_hash[:node_groups].split(',')
    add_groups = new_groups - old_groups
    del_groups = old_groups - new_groups
    add_groups.each do |group|
      args = ['-assign_node']
      args << "node_name=#{resource[:name]}"
      args << "group_name=#{group}"
      args << "net_type=#{@property_hash[:network_type]}" if @property_hash.include? :network_type
      opcnode(*args)
    end
    del_groups.each do |group|
      args = ['-deassign_node']
      args << "node_name=#{resource[:name]}"
      args << "group_name=#{group}"
      args << "net_type=#{@property_hash[:network_type]}" if @property_hash.include? :network_type
      opcnode(*args)
    end
  end

  def layout_groups=(new_value)
    is = @property_hash[:layout_groups] || {}

    new_value.each do |hierarchy,group|
      unless is[hierarchy] == group
        args = ['-move_nodes']
        args << "node_list=#{resource[:name]}"
        args << "node_hier=#{hierarchy}"
        args << "layout_group=#{group}"
        args << "net_type=#{@property_hash[:network_type]}" if @property_hash.include? :network_type
        opcnode(*args)
      end
    end
  end

  def network_type=(new_value)
    raise Puppet::Error, "Changing network_type is not supported by opcnode"
  end

  def label=(new_value)
    raise Puppet::Error, "Changing label is not supported by opcnode"
  end

  def ipaddress=(new_value)
    raise Puppet::Error, "Changing ipaddress is not supported by opcnode"
  end

end
