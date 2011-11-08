#!/usr/bin/env ruby

require 'spec_helper'
require 'nokogiri'

describe Puppet::Type.type(:om_heartbeat).provider(:parse_nokogiri), '(integration)' do
  include PuppetSpec::Files

  before :each do
    @xml = tmpfile('puppet_heartbeat.xml')
    FileUtils.cp(my_fixture('input.xml'), @xml)
    described_class.stubs(:configfile).returns @xml
    described_class.stubs(:suitable?).returns true
    Puppet::Type::Om_heartbeat.stubs(:defaultprovider).returns described_class
  end

  after :each do
    described_class.initvars
  end

  def run_in_catalog(*resources)
    catalog = Puppet::Resource::Catalog.new
    catalog.host_config = false
    resources.each do |resource|
      resource.expects(:err).never
      catalog.add_resource(resource)
    end
    catalog.apply
  end

  describe "when host is present and should be removed" do

    it "should be able to remove a host with no heartbeat" do
      expected_output = File.read(my_fixture('destroy_host_no_heartbeat.xml'))
      resource = Puppet::Type.type(:om_heartbeat).new(
        :name   => 'test01.example.com',
        :ensure => :absent
      )
      run_in_catalog(resource)
      File.read(described_class.configfile).should == expected_output
    end

    it "should be able to remove a host with a single heartbeat" do
      expected_output = File.read(my_fixture('destroy_host_one_heartbeat.xml'))
      resource = Puppet::Type.type(:om_heartbeat).new(
        :name   => 'second-test.example.com',
        :ensure => :absent
      )
      run_in_catalog(resource)
      File.read(described_class.configfile).should == expected_output
    end

    it "should be able to remove a host with multiple heartbeats" do
      expected_output = File.read(my_fixture('destroy_host_multiple_heartbeat.xml'))
      resource = Puppet::Type.type(:om_heartbeat).new(
        :name   => 'www.example.com',
        :ensure => :absent
      )
      run_in_catalog(resource)
      File.read(described_class.configfile).should == expected_output
    end

  end

  describe "when host is absent and should be created" do

    it "should be able to create a host with no heartbeat" do
      expected_output = File.read(my_fixture('create_host_no_heartbeat.xml'))
      resource = Puppet::Type.type(:om_heartbeat).new(
        :name   => 'foo.example.com',
        :ensure => :present
      )
      run_in_catalog(resource)
      File.read(described_class.configfile).should == expected_output
    end

    it "should be able to create a host with one heartbeat" do
      expected_output = File.read(my_fixture('create_host_one_heartbeat.xml'))
      resource = Puppet::Type.type(:om_heartbeat).new(
        :name       => 'foo.example.com',
        :heartbeats => 'SimpleHeartBeat',
        :ensure     => :present
      )
      run_in_catalog(resource)
      File.read(described_class.configfile).should == expected_output
    end

    it "should be able to create a host with multiple heartbeats" do
      expected_output = File.read(my_fixture('create_host_one_heartbeat.xml'))
      resource = Puppet::Type.type(:om_heartbeat).new(
        :name       => 'foo.example.com',
        :heartbeats => 'SimpleHeartBeat',
        :ensure     => :present
      )
      run_in_catalog(resource)
      File.read(described_class.configfile).should == expected_output
    end

  end

  describe "when heartbeats is out of sync" do

    it "should add missing heartbeats" do
      expected_output = File.read(my_fixture('add_heartbeat.xml'))
      resource = Puppet::Type.type(:om_heartbeat).new(
        :name       => 'second-test.example.com',
        :heartbeats => [ 'SimpleHeartBeat', 'AdvancedHeartBeat' ],
        :ensure     => :present
      )
      run_in_catalog(resource)
      File.read(described_class.configfile).should == expected_output
    end

    it "should remove additional heartbeats" do
      expected_output = File.read(my_fixture('remove_heartbeat.xml'))
      resource = Puppet::Type.type(:om_heartbeat).new(
        :name       => 'www.example.com',
        :heartbeats => [ 'AdvancedHeartBeat' ],
        :ensure     => :present
      )
      run_in_catalog(resource)
      File.read(described_class.configfile).should == expected_output
    end

  end

  describe "when having multiple resources in the catalog" do

    it "should produce the correct endresult" do
      expected_output = File.read(my_fixture('multiple.xml'))
      resource_del = Puppet::Type.type(:om_heartbeat).new(
        :name       => 'www.example.com',
        :ensure     => :absent
      )
      resource_add = Puppet::Type.type(:om_heartbeat).new(
        :name       => 'new.example.com',
        :ensure     => :present,
        :heartbeats => [ 'SimpleHeartBeat' ]
      )
      resource_mod = Puppet::Type.type(:om_heartbeat).new(
        :name       => 'second-test.example.com',
        :ensure     => :present,
        :heartbeats => [ 'AdvancedHeartBeat' ]
      )
      run_in_catalog(resource_del,resource_add,resource_mod)
      File.read(described_class.configfile).should == expected_output

    end

  end

end
