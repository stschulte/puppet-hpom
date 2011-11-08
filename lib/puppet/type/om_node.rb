require 'puppet/property/list'
require 'puppet/property/keyvalue'

module Puppet
  newtype(:om_node) do

    @doc = "Mangages a node in HP Operations Manager.  It can be used
      to add a node, assign node groups, and assign layout groups"

    ensurable

    newparam(:name) do
      desc "The name of the node.  This is most likely the full
        qualified domainname of the node"

      isnamevar

      validate do |value|
        raise Puppet::Error, "Name must not contain whitespace: #{value}" if value =~ /\s/
        raise Puppet::Error, "Name must not be empty" if value.empty?
      end

    end

    newproperty(:label) do
      desc "The label of the node.  This is the name you see in
        the Node Bank"

    end

    newproperty(:ipaddress) do
      desc "The IP address.  If you dont specify an IP address the server will
        resolve the node name when it adds a node"

      validate do |value|
        # regex copied from host type
        raise Puppet::Error, "Invalid ip address: #{value}" unless value =~ /^((([0-9a-fA-F]+:){7}[0-9a-fA-F]+)|(([0-9a-fA-F]+:)*[0-9a-fA-F]+)?::(([0-9a-fA-F]+:)*[0-9a-fA-F]+)?)|((25[0-5]|2[0-4][\d]|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})$/
      end

    end

    newproperty(:network_type) do
      desc "The network type.  This should always be NETWORK_IP which is the
        default value.  So you will never have to specify this property by
        yourself.  It accepts the same values as the opcnode command"

      newvalue :NETWORK_NO_NODE
      newvalue :NETWORK_IP
      newvalue :NETWORK_OTHER
      newvalue :NETWORK_UNKNOWN
      newvalue :PATTERN_IP_ADDR
      newvalue :PATTERN_IP_NAME
      newvalue :PATTERN_OTHER

      defaultto :'NETWORK_IP'
    end

    newproperty(:machine_type) do
      desc "The machine type describes the architecture of the host you want
        to add.  See `man opcnode` to get a full list."

      newvalue :MACH_BBC_LX26RPM_X64
      newvalue :MACH_BBC_OTHER_IP
      newvalue :MACH_BBC_SOL10_X86
      newvalue :MACH_BBC_LX26RPM_IPF64
      newvalue :MACH_BBC_LX26RPM_X86
      newvalue :MACH_BBC_WINXP_IPF64
      newvalue :MACH_BBC_OTHER_NON_IP
      newvalue :MACH_BBC_LX26RPM_PPC
      newvalue :MACH_BBC_HPUX_IPF32
      newvalue :MACH_BBC_HPUX_PA_RISC
      newvalue :MACH_BBC_AIX_K64_PPC
      newvalue :MACH_BBC_AIX_PPC
      newvalue :MACH_BBC_WIN2K3_X64
      newvalue :MACH_BBC_WINNT_X86
      newvalue :MACH_BBC_SOL_SPARC

    end

    newproperty(:communication_type) do
      desc "Defines how the node communicates with the OM Server.  You
        should probably always use black box communcation (HTTPS) which is
        in fact the default value.  So you probably never have to set the
        property explicitly.  See `man opcnode` for different values"


      newvalue :COMM_UNSPEC_COMM
      newvalue :COMM_BBC

      defaultto :COMM_BBC
    end

    newproperty(:node_type) do
      desc "Describes the type of the node.  You can use this property to enable or
        disable a node.  The default is MONITORED."

      newvalue :DISABLED
      newvalue :CONTROLLED
      newvalue :MONITORED
      newvalue :MESSAGE_ALLOWED

      defaultto :CONTROLLED
    end

    newproperty(:dynamic_ip) do
      desc "Controls whether or not the node uses dhcp and may have different ip
        addresses"

      newvalues :no, :yes
      aliasvalue :true, :yes
      aliasvalue :false, :no
    end

    newproperty(:layout_groups, :parent => Puppet::Property::KeyValue) do
      desc "The layoutgroups the node should appear in.  If you have more
        than one node hierarchy the node may appear in multiple layout groups
        (one for each hierarchy) so can specify more than one value as an array.
        The syntax to specify a layoutgroup is `Group/Subgroup/SubSubgroup`.  To
        specify a layoutgroup that is not in the default hierarchy NodeBank you have
        to prefix the string with `/Hierarchy/Layoutgroup/Subgroup/...`.

        Example:

            # Put node in group `Solaris`, subgroup `SPARC`, nodehierarchy `NodeBank`
            layout_groups => 'Solaris/SPARC'

            # above plus assign to layoutgroup `Server/SUN` of a different hierarchy
            layout_groups => [ 'Solaris/SPARC', '/CustomHierachy/Server/SUN' ]

            # NOT ALLOWED because each node can only be in one layoutgroup per nodehierarchy
            layout_groups => [ 'Solaris/SPARC, '/NodeBank/Unix' ]"

      def inclusive?
        false
      end

      def hash_to_key_value_s(hash)
        hash.collect { |k,v| "/#{k}/#{v}" }.join(',')
      end

      def hashify(keyvalue_array)
        hash = {}
        keyvalue_array.each do |path|
          if match = %r{^/([^/]+)/(.*)$}.match(path)
            hash[match.captures[0].intern] = match.captures[1]
          else
            hash[:NodeBank] = path
          end
        end
        hash
      end

      validate do |value|
        raise Puppet::Error, 'layout_groups have to be specified as an array, not a comma separated list' if value =~ /,/
      end
    end

    newproperty(:node_groups, :parent => Puppet::Property::List) do
      desc "The node groups the node should be in.  Multiple groups
        have to be specified as an array"

      def inclusive?
        true
      end

      validate do |value|
        raise Puppet::Error, 'node_groups have to be specified as an array, not a comma separated list' if value =~ /,/
      end

    end

    validate do
      if paths = @original_parameters[:layout_groups]
        seen_hierarchies = []
        paths.each do |path|
          h = :NodeBank
          if match = %r{/([^/]+)/}.match(path)
            h = match.captures.first.intern
          end
          if seen_hierarchies.include? h
            raise Puppet::Error, "layout_groups must not include multiple groups of the same hierarchy: #{h}"
          else
            seen_hierarchies << h
          end
        end
      end
    end

  end

end
