#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_fsmon) do

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

    [:warning, :minor, :major, :critical].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end

  end

  describe "when validating value" do

    describe "for name" do

      it "should support a valid name" do
        proc { described_class.new(:name => '/mnt/foo') }.should_not raise_error
        proc { described_class.new(:name => '/') }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { described_class.new(:name => '/mnt/foo bar') }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => '/mnt/foo ') }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => ' /mnt') }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => "/mnt\tfoo") }.should raise_error(Puppet::Error, /Name.*whitespace/)
      end

      it "should not support an empty name" do
        proc { described_class.new(:name => '') }.should raise_error(Puppet::Error, /Name.*empty/)
      end

    end

    [:warning, :minor, :major, :critical].each do |property|
      describe property do

        it "should support absent" do
          proc { described_class.new(:name => '/mnt/foo', property => :absent) }.should_not raise_error
        end

        it "should support valid values" do
          proc { described_class.new(:name => '/mnt/foo', property => '0') }.should_not raise_error
          proc { described_class.new(:name => '/mnt/foo', property => '1') }.should_not raise_error
          proc { described_class.new(:name => '/mnt/foo', property => '99') }.should_not raise_error
          proc { described_class.new(:name => '/mnt/foo', property => '100') }.should_not raise_error
        end

        it "should support 101 as a special value" do
          proc { described_class.new(:name => '/mnt/foo', property => '101') }.should_not raise_error
        end

        it "should not support not numeric values" do
          proc { described_class.new(:name => '/mnt/foo', property => '10a') }.should raise_error(Puppet::Error, /#{property}.*has to be numeric/i)
          proc { described_class.new(:name => '/mnt/foo', property => '1a0') }.should raise_error(Puppet::Error, /#{property}.*has to be numeric/i)
          proc { described_class.new(:name => '/mnt/foo', property => 'a10') }.should raise_error(Puppet::Error, /#{property}.*has to be numeric/i)
          proc { described_class.new(:name => '/mnt/foo', property => '1-0') }.should raise_error(Puppet::Error, /#{property}.*has to be numeric/i)
          proc { described_class.new(:name => '/mnt/foo', property => '') }.should raise_error(Puppet::Error, /#{property}.*has to be numeric/i)
          proc { described_class.new(:name => '/mnt/foo', property => 'a') }.should raise_error(Puppet::Error, /#{property}.*has to be numeric/i)
        end

        it "should not support values out of range" do
          proc { described_class.new(:name => '/mnt/foo', property => '102') }.should raise_error(Puppet::Error, /#{property}.*out of range/i)
          proc { described_class.new(:name => '/mnt/foo', property => '112') }.should raise_error(Puppet::Error, /#{property}.*out of range/i)
          proc { described_class.new(:name => '/mnt/foo', property => '200') }.should raise_error(Puppet::Error, /#{property}.*out of range/i)
        end

      end
    end
  end
end
