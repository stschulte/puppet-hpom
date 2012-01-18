#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_dbspi_option) do

  before do
    @provider_class = described_class.provide(:fake) { mk_resource_methods }
    @provider_class.stubs(:suitable?).returns true
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

    [:ensure, :value, :target ].each do |property|
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
        proc { described_class.new(:name => 'TEST01E', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'ORA_LOW_LEVEL_SEGMENT_QUERY', :ensure => :present) }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { described_class.new(:name => 'TEST 01E', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => 'TEST01E ', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => ' TEST01E', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => "TEST\t01E", :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
      end

      it "should not support an empty name" do
        proc { described_class.new(:name => '', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*empty/)
      end
    end

    describe "value" do

      it "should support simple words" do
        proc { described_class.new(:name => 'TEST01E', :value => 'ON') }.should_not raise_error
        proc { described_class.new(:name => 'TEST01E', :value => 'OFF') }.should_not raise_error
      end

    end

  end

end
