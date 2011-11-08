module Puppet
  newtype(:om_fsmon) do

    @doc = "Mangages thresholds for filesystem monitoring
      on HP Operations Manager nodes."

    newparam(:name) do
      desc "The file path for which the thresholds should
        apply"

      isnamevar

      validate do |value|
        raise Puppet::Error, "Name must not contain whitespace: #{value}" if value =~ /\s/
        raise Puppet::Error, "Name must not be empty" if value.empty?
      end
    end

    newproperty(:warning) do
      desc "The filesystem usage in percent that has to be reached to
        generate a warning message.  Use absent to remove a possible specific
        threshold so the default threshold will take over.  Specify a value of
        101 to never raise a warning."

      newvalues /\d+/, :absent
      validate do |value|
        return if [:absent,'absent',:disable].include? value
        raise Puppet::Error, "Warning has to be numeric, not #{value}" unless value =~ /^\d+$/
        raise Puppet::Error, "Warning out of range (0-101): #{value}" unless (0..101).include?(Integer(value))
      end
    end

    newproperty(:minor) do
      desc "The filesystem usage in percent that has to be reached to
        generate a minor message.  Use absent to remove a possible specific
        threshold so the default threshold will take over.  Specify a value of
        101 to never raise a minor message."

      newvalues /\d+/, :absent
      validate do |value|
        return if [:absent,'absent'].include? value
        raise Puppet::Error, "Minor has to be numeric, not #{value}" unless value =~ /^\d+$/
        raise Puppet::Error, "Minor out of range (0-101): #{value}" unless (0..101).include?(Integer(value))
      end
    end

    newproperty(:major) do
      desc "The filesystem usage in percent that has to be reached to
        generate a major message.  Use absent to remove a possible specific
        threshold so the default threshold will take over.  Specify a value of
        101 to never raise a major message."

      newvalues /^\d+$/, :absent
      validate do |value|
        return if [:absent,'absent'].include? value
        raise Puppet::Error, "Major has to be numeric, not #{value}" unless value =~ /^\d+$/
        raise Puppet::Error, "Major out of range (0-101): #{value}" unless (0..101).include?(Integer(value))
      end
    end

    newproperty(:critical) do
      desc "The filesystem usage in percent that has to be reached to
        generate a critical message.  Use absent to remove a possible specific
        threshold so the default threshold will take over.  Specify a value of
        101 to never raise a critical message."

      newvalues /\d+/, :absent
      validate do |value|
        return if [:absent,'absent'].include? value
        raise Puppet::Error, "Critical has to be numeric, not #{value}" unless value =~ /^\d+$/
        raise Puppet::Error, "Critical out of range (0-101): #{value}" unless (0..101).include?(Integer(value))
      end
    end

  end
end
