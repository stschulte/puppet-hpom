require 'puppet/property/list'
module Puppet
  newtype(:om_heartbeat) do

    @doc = "Mangages which heartbeats a specific HP Operations Manager node
      has to send to the management server"

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

    newproperty(:heartbeats, :parent => Puppet::Property::List) do

      validate do |value|
        raise Puppet::Error, 'heartbeats have to be specified as an array, not a comma separated list' if value =~ /,/
        super
      end

      def inclusive?
        true
      end

    end

  end

end
