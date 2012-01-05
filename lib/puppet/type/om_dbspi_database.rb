require 'puppet/property/keyvalue'

module Puppet
  newtype(:om_dbspi_database) do

    @doc = "Manages database entries in the dbspi (HP DB Smart Plugin) configuration you
      would normally do with dbspicfg.sh"

    newparam(:name) do
      desc "The name of the database"

      isnamevar

      validate do |value|
        raise Puppet::Error, "Name must not contain whitespace: #{value}" if value =~ /\s/
        raise Puppet::Error, "Name must not be empty" if value.empty?
      end
    end

    ensurable

    newproperty(:connect) do
      desc "The connection string to connect to the database"
    end

    newproperty(:logfile) do
      desc "The path to the alert log file"

      validate do |value|
        raise Puppet::Error, "Logfile must be an absolute path: #{value}" unless value =~ /^\//
      end
    end

    newproperty(:home) do
      desc "The homedirectory of the database server installation"

      validate do |value|
        raise Puppet::Error, "Home must be an absolute path: #{value}" unless value =~ /^\//
      end
    end

    newproperty(:type) do
      desc "The type of the database. Currently only oracle is supported"

      newvalues :oracle
      defaultto :oracle
    end

    newproperty(:filter, :parent => Puppet::Property::KeyValue) do
      desc "Custom filters that change the resulting sql statement when the dbspi
        execute a metric.  You should pass an array of key-value-pairs of the form
        metricnumber: where statement.

        Example:

            filter => [
              '16:contents != \'UNDO\'',
              '213:contents != \'UNDO\'',
            ]"

      def membership
        :filter_membership
      end

      def process_current_hash(current)
        return {} if current == :absent or inclusive?
        current
      end

      def hash_to_key_value_s(hash)
        hash.collect{|k,v| "#{k}:#{v}"}.join(',')
      end

      def hashify(keyvalue_array)
        keyvalue_array.inject({}) do |hash,assignment|
          key,value = assignment.split(':',2)
          hash[key.intern] = value
          hash
        end
      end

      validate do |value|
        raise Puppet::Error, 'Filter have to be specified as an array, not a comma separated list' if value =~ /,/
        raise Puppet::Error, "Filter must be of the form 'metric#:where statement', not #{value}" unless value =~ /^[0-9]+:.+$/
      end
    end

    newparam(:filter_membership) do
      desc "Whether the specified filter statements should be treated as the
        only statements or whether they should merely be treated as the minumum list."

      newvalues :inclusive, :minimum

      defaultto :inclusive
    end

  end
end
