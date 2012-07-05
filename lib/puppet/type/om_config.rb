module Puppet
  newtype(:om_config) do

    @doc = "This type can be used to specify an HP OM agent config setting.
      HP Operations Manager uses an ini-like configuration with different
      namespaces. As a result the resource's name must always include the
      namespace and has to be of the form `<namespace>/<configsetting>`.

      To make sure a specic config setting has the desired value:

          om_config { 'eaagt/OPC_TRACE':
            ensure => present,
            value  => 'TRUE',
          }

      You can also make sure a setting is cleared by setting ensure to
      absent:

          om_config { 'eaagt/OPC_TRACE':
            ensure => absent,
          }
      "


    newparam(:name) do
      desc "The agentsetting's name. The name has to be of the form <namespace>/<key>"

      isnamevar

      validate do |value|
        unless value =~ /^\S+\/\S+$/
          raise Puppet::Error, "Name must be of the form <namespace>/<key>, not #{value}"
        end
      end
    end

    ensurable

    newproperty(:value) do
      desc "The desired value of the agent configsetting"
    end

  end
end
