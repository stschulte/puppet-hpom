#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_fsmon).provider(:ovconfchg) do

  before :each do
    described_class.stubs(:suitable).returns true
    Puppet::Type.type(:om_fsmon).stubs(:defaultprovider).returns described_class
  end

  it "should support prefetching" do
    described_class.should respond_to :prefetch
  end

  it "should support instances" do
    described_class.should respond_to :instances
  end

  [:warning,:minor,:major,:critical].each do |property|
    it "should have getter and setter for property #{property}" do
      described_class.new.should respond_to property
      described_class.new.should respond_to "#{property}=".intern
    end
  end


  describe "when calling instances" do

    it "should print a debug message when a setting is not present" do
      ['SpaceUtilWarningThreshold', 'SpaceUtilMinorThreshold', 'SpaceUtilMajorThreshold', 'SpaceUtilCriticalThreshold'].each do |om_property|
        described_class.stubs(:ovconfget).with('eaagt',om_property).returns "\n"
        described_class.expects(:debug).with("#{om_property} in section eaagt not yet present")
      end
      described_class.instances
    end

    it "should print a warning about unexpected lines" do
      ['SpaceUtilWarningThreshold', 'SpaceUtilMinorThreshold', 'SpaceUtilMajorThreshold', 'SpaceUtilCriticalThreshold'].each do |om_property|
        described_class.stubs(:ovconfget).with('eaagt',om_property).returns "70,/mnt/foo=30,/mnt/bar"
        described_class.expects(:warn).with("Unable to interpret assignment /mnt/bar of threshold #{om_property}")
      end
      described_class.instances
    end


    describe "when parsing correct lines" do

      before :each do
        described_class.stubs(:ovconfget).with('eaagt','SpaceUtilWarningThreshold').returns "70,/mnt/foo=60,/=80,/mnt/baz=100\n"
        described_class.stubs(:ovconfget).with('eaagt','SpaceUtilMinorThreshold').returns "80,/=85,/mnt/baz=100\n"
        described_class.stubs(:ovconfget).with('eaagt','SpaceUtilMajorThreshold').returns "90,/=95,/mnt/baz=100\n"
        described_class.stubs(:ovconfget).with('eaagt','SpaceUtilCriticalThreshold').returns "95,/=98,/mnt/baz=100,/tmp=92\n"
        @instances = described_class.instances.sort_by { |p| p.get(:name) }
        @instances.size.should == 4
      end

      it "should be able to parse /" do
        @instances[0].get(:warning).should == '80'
        @instances[0].get(:minor).should == '85'
        @instances[0].get(:major).should == '95'
        @instances[0].get(:critical).should == '98'
      end

      it "should be able to parse /mnt/baz" do
        @instances[1].get(:name).should == '/mnt/baz'
        @instances[1].get(:warning).should == '100'
        @instances[1].get(:minor).should == '100'
        @instances[1].get(:major).should == '100'
        @instances[1].get(:critical).should == '100'
      end

      it "should be able to parse /mnt/foo" do
        @instances[2].get(:name).should == '/mnt/foo'
        @instances[2].get(:warning).should == '60'
        @instances[2].get(:minor).should == :absent
        @instances[2].get(:major).should == :absent
        @instances[2].get(:critical).should == :absent
      end

      it "should be able to parse /mnt/tmp" do
        @instances[3].get(:name).should == '/tmp'
        @instances[3].get(:warning).should == :absent
        @instances[3].get(:minor).should == :absent
        @instances[3].get(:major).should == :absent
        @instances[3].get(:critical).should == '92'
      end

    end

  end

end
