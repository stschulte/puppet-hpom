module Puppet
  newtype(:om_dbspi_option) do

    @doc = "Can be used to define options in the configuration file of
      the DB SPI"

    newparam(:name) do
      desc "The option name"

      isnamevar

      validate do |value|
        raise Puppet::Error, "Name must not contain whitespace: #{value}" if value =~ /\s/
        raise Puppet::Error, "Name must not be empty" if value.empty?
      end
    end

    ensurable

    newproperty(:value) do
      desc "the value which should be assigned to the option"
    end

    newproperty(:target) do
      desc "the path of the target file to store parameters in"

      defaultto do
        if @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
          @resource.class.defaultprovider.default_target
        else
          nil
        end
      end
    end

  end
end
