#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_heartbeat) do

  before do
    @provider_class = described_class.provide(:fake) { mk_resource_methods }
    @provider_class.stubs(:suitable).returns true
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  it "should have :name as its keyattribute" do
    described_class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :heartbeats ].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating value" do

    describe "for ensure" do
      it "should support present" do
        proc { described_class.new(:name => 'foo', :ensure => :present) }.should_not raise_error
      end

      it "should support absent" do
        proc { described_class.new(:name => 'foo', :ensure => :absent) }.should_not raise_error
      end

      it "should not support other values" do
        proc { described_class.new(:name => 'foo', :ensure => :foo) }.should raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe "for name" do
      it "should support a valid name" do
        proc { described_class.new(:name => 'test.example.com', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'test', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => '10.99.1.1', :ensure => :present) }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { described_class.new(:name => 'test com', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => 'testcom ', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => ' testcom', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => "test\tcom", :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
      end

      it "should not support an empty name" do
        proc { described_class.new(:name => '', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*empty/)
      end
    end

    describe "heartbeats" do

      it "should support simple words" do
        proc { described_class.new(:name => 'test.example.com', :heartbeats => 'simple') }.should_not raise_error
      end

      it "should support whitespace" do
        proc { described_class.new(:name => 'test.example.com', :heartbeats => 'with space') }.should_not raise_error
      end

      it "should support multiple heartbeats as an array" do
        proc { described_class.new(:name => 'test.example.com', :heartbeats => [ 'one', 'two']) }.should_not raise_error
        proc { described_class.new(:name => 'test.example.com', :heartbeats => [ 'one' ]) }.should_not raise_error
        proc { described_class.new(:name => 'test.example.com', :heartbeats => [ 'three', 'two', 'one', 'with space']) }.should_not raise_error
      end

      it "should not support a comma separated list" do
        proc { described_class.new(:name => 'test.example.com', :heartbeats => 'one,two') }.should raise_error(Puppet::Error, /have to be specified as an array/)
      end

    end

  end

  describe "when syncing" do

    describe "property hearbeats" do

      before :each do
        @provider = @provider_class.new(:name => 'host.example.com', :heartbeats => '')
        @resource = described_class.new(:name => 'host.example.com', :ensure => :present, :heartbeats => ['sap','ping','cron'])
        @resource.provider = @provider
        @property = @resource.parameter(:heartbeats)
      end

      it "should send the sorted joined array to the provider" do
        @provider.expects(:'heartbeats=').with('cron,ping,sap')
        @property.sync
      end

      it "should not care about the order of heartbeats" do
        @property.insync?(%w{cron ping sap}).should == true
        @property.insync?(%w{cron sap ping}).should == true
        @property.insync?(%w{sap cron ping}).should == true
        @property.insync?(%w{sap ping cron}).should == true
        @property.insync?(%w{ping sap cron}).should == true
        @property.insync?(%w{ping cron sap}).should == true
      end
    end

  end

end
