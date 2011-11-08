#!/usr/bin/env ruby

require 'spec_helper'
require 'nokogiri'

describe Puppet::Type.type(:om_heartbeat).provider(:parse_nokogiri) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:om_heartbeat).stubs(:defaultprovider).returns described_class
  end

  after :each do
    described_class.initvars
  end

  it "should support prefetching" do
    described_class.should respond_to :prefetch
  end

  it "should support instances" do
    described_class.should respond_to :instances
  end

  [:heartbeats,].each do |property|
    it "should have getter and setter for property #{property}" do
      described_class.new.should respond_to property
      described_class.new.should respond_to "#{property}=".intern
    end
  end

  describe "when running instances" do

    it "should parse correct xml files" do
      described_class.stubs(:configfile).returns my_fixture('simple.xml')
      described_class.expects(:warning).never
      instances = described_class.instances.map do |prov|
        { :name => prov.get(:name), :heartbeats => prov.get(:heartbeats) }
      end.sort_by { |params| params[:name] }
      instances[0].should == {:name => 'second-test.example.com', :heartbeats => 'SimpleHeartBeat' }
      instances[1].should == {:name => 'test01.example.com',      :heartbeats => 'AdvancedHeartBeat' }
      instances[2].should == {:name => 'www.example.com',         :heartbeats => 'SimpleHeartBeat,AdvancedHeartBeat' }
    end

    it "should warn about missing host entries" do
      described_class.stubs(:configfile).returns my_fixture('missing_host_entry.xml')
      described_class.expects(:warning).with('Host test02.example.com is assigned to heartbeat AdvancedHeartBeat but does not appear in host list. Ignore this assignment')
      described_class.instances
    end

    it "should warn about missing name attribute on host entries" do
      described_class.stubs(:configfile).returns my_fixture('missing_name_attribute_on_host.xml')
      described_class.expects(:warning).with('Found host element with no name attribute')
      described_class.instances
    end

    it "should warn about duplicate heartbeat assignments" do
      described_class.stubs(:configfile).returns my_fixture('double_heartbeat.xml')
      described_class.expects(:warning).with('Host www.example.com already assigned to heartbeat AdvancedHeartBeat')
      described_class.instances
    end

    it "should warn about missing name attributes on heartbeat entry" do
      described_class.stubs(:configfile).returns my_fixture('missing_name_attribute_on_heartbeat.xml')
      described_class.expects(:warning).with('Found heartbeat with no name attribute. Heartbeat is ignored')
      described_class.instances
    end

    it "should warn about missing host attributes on rules" do
      described_class.stubs(:configfile).returns my_fixture('missing_host_attribute.xml')
      described_class.expects(:warning).with('Found rule inside heartbeat AdvancedHeartBeat with no host attribute')
      described_class.instances
    end

  end

end
