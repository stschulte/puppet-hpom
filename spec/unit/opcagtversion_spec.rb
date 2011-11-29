#!/usr/bin/env ruby

require 'spec_helper'
require 'facter'

describe Facter::Util::Fact, 'opcagtversion' do

  after :each do
    Facter.clear
  end

  describe "when the HP Operations Manager agent is installed" do
    it "should return the version" do
      Facter::Util::Resolution.stubs(:exec).with('/opt/OV/bin/opcagt -version').returns('11.01.056')
      Facter.fact(:opcagtversion).value.should == '11.01.056'
    end
  end

  describe "when the HP Operations Manager is not installed" do
    it "should not raise an error" do
      FileTest.stubs(:exists?).with('/opt/OV/bin/opcagt').returns false
      proc { Facter.fact(:opcagtversion).value }.should_not raise_error
    end
    it "should return nil" do
      Facter.clear
      FileTest.stubs(:exists?).with('/opt/OV/bin/opcagt').returns false
      Facter.fact(:opcagtversion).value.should be_nil
    end
  end

end

