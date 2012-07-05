#!/usr/bin/env rspec

require 'spec_helper'

describe Puppet::Type.type(:om_config).provider(:ovconfchg) do

  before :each do
    Puppet::Type.type(:om_config).stubs(:defaultprovider).returns described_class
    described_class.stubs(:suitable?).returns true
  end

  describe ".instances" do
    it "should have an instances method" do
      described_class.should respond_to :instances
    end

    it "should get a list of config options by runnig ovconfget" do
      described_class.expects(:ovconfget).returns File.read(my_fixture('simple'))
      described_class.expects(:warning).never
      described_class.instances.map do |p|
        Hash[
          :name   => p.get(:name),
          :ensure => p.get(:ensure),
          :value  => p.get(:value)
        ]
      end.should == [
        {:name => 'depl.mechanisms.ssh/COPY', :ensure => :present, :value => 'scp  @:'},
        {:name => 'depl.mechanisms.ssh/EXEC', :ensure => :present, :value => 'ssh -q -2 @ '},
        {:name => 'eaagt/OPC_BUFLIMIT_SEVERITY', :ensure => :present, :value => 'major' },
        {:name => 'eaagt/OPC_HBP_INTERVAL_ON_AGENT', :ensure => :present, :value => '-1'},
        {:name => 'eaagt/OPC_INSTALLATION_TIME', :ensure => :present, :value => 'Mon Nov  8 14:51:51 EST 2010'},
        {:name => 'eaagt.lic.data/ovoagt', :ensure => :present, :value => '1'}
      ]
    end

    it "should complain about a key with no preceding section" do
      described_class.expects(:ovconfget).returns File.read(my_fixture('invalid'))
      described_class.expects(:warning).with('Found key-value-pair ("foo=bar") but no preceding namespace. Line is ignored')
      described_class.expects(:warning).with('Unexpected line "no value". Line is ignored')
      described_class.instances.map{|p| {:name => p.get(:name), :value => p.get(:value)}}.should == [
        {:name => 'depl.mechanisms.ssh/EXEC', :value => 'ssh -q -2 @ '}
      ]
    end

    it "should ignore comments" do
      described_class.expects(:ovconfget).returns File.read(my_fixture('comment'))
      described_class.expects(:warning).never
      described_class.instances.map{|p| {:name => p.get(:name), :value => p.get(:value)}}.should == [
        {:name => 'depl.mechanisms.ssh/COPY', :value => 'scp  @:'},
        {:name => 'depl.mechanisms.ssh/EXEC', :value => 'ssh -q -2 @ '},
        {:name => 'eaagt.lic.data/ovoagt', :value => '1'}
      ]
    end

    it "should ignore blank lines" do
      described_class.expects(:ovconfget).returns File.read(my_fixture('blank'))
      described_class.expects(:warning).never
      described_class.instances.map{|p| {:name => p.get(:name), :value => p.get(:value)}}.should == [
        {:name => 'depl.mechanisms.ssh/COPY', :value => 'scp  @:'},
        {:name => 'depl.mechanisms.ssh/EXEC', :value => 'ssh -q -2 @ '},
        {:name => 'eaagt.lic.data/ovoagt', :value => '1'}
      ]
    end
  end

  describe "#exists?" do
    it "should return true if resource is present" do
      prov = described_class.new(:name => 'eaagt/OPC_NODENAME', :value => 'foo.example.com', :ensure => :present)
      prov.should be_exists
    end

    it "should return false if resource is absent" do
      prov = described_class.new(:name => 'eaagt/OPC_NODENAME', :value => 'foo.example.com', :ensure => :absent)
      prov.should_not be_exists
    end
  end

  describe "#create" do
    it "should create the key by runnig ovconfchg set" do
      prov = described_class.new(Puppet::Type.type(:om_config).new(
        :name   => 'eaagt.lic.data/ovoagt',
        :ensure => :present,
        :value  => '1'
      ))
      prov.expects(:ovconfchg).with('-ns', 'eaagt.lic.data', '-set', 'ovoagt', '1')
      prov.create
    end

    it "should complain about a missing value" do
      prov = described_class.new(Puppet::Type.type(:om_config).new(
        :name   => 'eaagt.lic.data/ovoagt',
        :ensure => :present
      ))
      expect { prov.create }.to raise_error(Puppet::Error, 'Cannot create key eaagt.lic.data/ovoagt without a value')
    end
  end

  describe "#destroy" do
    it "should remove the key by running ovconfchg clear" do
      prov = described_class.new(Puppet::Type.type(:om_config).new(
        :name   => 'eaagt.lic.data/ovoagt',
        :ensure => :absent,
        :value  => '1'
      ))
      prov.expects(:ovconfchg).with('-ns', 'eaagt.lic.data', '-clear', 'ovoagt')
      prov.destroy
    end

    it "should not complain about a missing value" do
      prov = described_class.new(Puppet::Type.type(:om_config).new(
        :name   => 'eaagt.lic.data/ovoagt',
        :ensure => :absent
      ))
      prov.expects(:ovconfchg).with('-ns', 'eaagt.lic.data', '-clear', 'ovoagt')
      prov.destroy
    end
  end

  describe "#value=" do
    it "should set the new value with ovconfchg" do
      prov = described_class.new(Puppet::Type.type(:om_config).new(
        :name   => 'agtrep/ACTION_TIMEOUT',
        :ensure => :present,
        :value  => '60'
      ))
      prov.expects(:ovconfchg).with('-ns', 'agtrep', '-set', 'ACTION_TIMEOUT', '60')
      prov.value = '60'
    end
  end

end
