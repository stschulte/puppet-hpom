#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_dbspi_option).provider(:parsed) do

  before :each do
    described_class.stubs(:suitable?).returns true
    described_class.stubs(:default_target).returns my_fixture('defaults')
    Puppet::Type.type(:om_dbspi_option).stubs(:defaultprovider).returns described_class
    @resource = Puppet::Type.type(:om_dbspi_option).new(
      :name   => 'dummy',
      :value  => 'ON',
      :ensure => :present
    )
    @provider = described_class.new(@resource)
  end

  [:destroy, :create, :exists?].each do |method|
    it "should respond to #{method}" do
      @provider.should respond_to method
    end
  end


  [:value].each do |property|
    it "should have getter and setter for property #{property}" do
      @provider.should respond_to property
      @provider.should respond_to "#{property}=".intern
    end
  end

  describe "when parsing a line" do

    it "should be able to capture the option name" do
      described_class.parse_line("OPTION ON")[:name].should == 'OPTION'
      described_class.parse_line("OPTION    ON")[:name].should == 'OPTION'
      described_class.parse_line("OPTION \t ON")[:name].should == 'OPTION'
    end

    it "should be able to capture the option value" do
      described_class.parse_line("OPTION ON")[:value].should == 'ON'
      described_class.parse_line("OPTION    ON")[:value].should == 'ON'
      described_class.parse_line("OPTION \t ON")[:value].should == 'ON'
    end

  end

  describe "when calling instances" do

    it "should be able to parse a default file" do
      @instances = described_class.instances

      @instances.size.should == 7

      @instances[0].get(:name).should == 'ORA_LOW_LEVEL_SEGMENT_QUERY'
      @instances[0].get(:value).should == 'OFF'

      @instances[1].get(:name).should == 'ORA_0X16_REPORT_DETAILS'
      @instances[1].get(:value).should == 'OFF'

      @instances[2].get(:name).should == 'ORA_X16_VIEWS'
      @instances[2].get(:value).should == 'ON'

      @instances[3].get(:name).should == 'DATABASE01'
      @instances[3].get(:value).should == 'ON'

      @instances[4].get(:name).should == 'DATABASE02'
      @instances[4].get(:value).should == 'OFF'

      @instances[5].get(:name).should == 'DATABASE03'
      @instances[5].get(:value).should == 'OFF'

      @instances[6].get(:name).should == 'DATABASE04'
      @instances[6].get(:value).should == 'ON'

    end

  end

end
