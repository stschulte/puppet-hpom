#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_dbspi_database) do

  before do
    @provider_class = described_class.provide(:fake) { mk_resource_methods }
    @provider_class.stubs(:suitable?).returns true
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  it "should have :name as its keyattribute" do
    described_class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name, :provider, :filter_membership].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :connect, :logfile, :filter, :home, :type ].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating value" do

    it "should complain when no home property is specified" do
      proc {
        described_class.new(:name => 'foo', :ensure => :present, :type => :oracle)
      }.should raise_error(Puppet::Error, /The properties type and home are mandatory attributes/)
    end

    it "should complain when no type property is specified" do
      # deactivate default for type property
      described_class.attrclass(:type).stubs(:method_defined?).with(:default).returns false
      proc {
        described_class.new(:name => 'foo', :ensure => :present, :home => '/my/home')
      }.should raise_error(Puppet::Error, /The properties type and home are mandatory attributes/)
    end

    it "should complain when both type and home are not specified" do
      proc {
        described_class.new(:name => 'foo', :ensure => :present)
      }.should raise_error(Puppet::Error, /The properties type and home are mandatory attributes/)
    end

    describe "for ensure" do
      it "should support present" do
        proc { described_class.new(:name => 'foo', :type => :oracle, :home => '/home', :ensure => :present) }.should_not raise_error
      end

      it "should support absent" do
        proc { described_class.new(:name => 'foo', :type => :oracle, :home => '/home', :ensure => :absent) }.should_not raise_error
      end

      it "should not support other values" do
        proc { described_class.new(:name => 'foo', :type => :oracle, :home => '/home', :ensure => :foo) }.should raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe "for name" do
      it "should support a valid name" do
        proc { described_class.new(:name => 'TestDB', :type => :oracle, :home => '/home', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'TEST01', :type => :oracle, :home => '/home', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'Test_DB', :type => :oracle, :home => '/home', :ensure => :present) }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { described_class.new(:name => 'test db', :type => :oracle, :home => '/home', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => 'testdb ', :type => :oracle, :home => '/home', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => ' testdb', :type => :oracle, :home => '/home', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => "test\tdb", :type => :oracle, :home => '/home', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
      end

      it "should not support an empty name" do
        proc { described_class.new(:name => '', :type => :oracle, :home => '/home', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*empty/)
      end
    end

    describe "for connect" do
      it "should support a valid connectstring" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :connect => 'user/password@host:1521/database', :ensure => :present) }.should_not raise_error
      end
    end

    describe "for logfile" do
      it "should support a valid path" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :logfile => '/u01/testdb/alert.log', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :logfile => '/u01/foo_bar/alert.log', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :logfile => '/alert.log', :ensure => :present) }.should_not raise_error
      end

      it "should not support a relative path" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :logfile => 'testdb/alert.log', :ensure => :present) }.should raise_error(Puppet::Error, /Logfile must be an absolute path/)
      end
    end

    describe "for home" do
      it "should support a valid path" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/u01/app/oracle/product/11.2.0/dbhome_1', :ensure => :present) }.should_not raise_error
      end

      it "should not support a relative path" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '11.2.0/dbhome_1', :ensure => :present) }.should raise_error(Puppet::Error, /Home must be an absolute path/)
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => 'dbhome_1', :ensure => :present) }.should raise_error(Puppet::Error, /Home must be an absolute path/)
      end
    end

    describe "for type" do
      [:oracle, :informix].each do |type|
        it "should support #{type}" do
          proc { described_class.new(:name => 'testdb', :home => '/home', :type => type, :ensure => :present) }.should_not raise_error
        end
      end

      it "should default to oracle" do
        described_class.new(:name => 'testdb', :home => '/home', :ensure => :present)[:type].should == :oracle
      end

      it "should not allow other types" do
        proc { described_class.new(:name => 'testdb', :home => '/home', :ensure => :present, :type => 'couchdb') }.should raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe "for filter" do
      it "should support a single assignment" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => '16:contents != \'UNDO\'', :ensure => :present) }.should_not raise_error
      end

      it "should support multiple filter definitions as an array" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => ['16:contents != \'UNDO\'', '213:content != \'UNDO\''], :ensure => :present) }.should_not raise_error
      end

      it "should not support a comma separated list" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => '16:contents != \'UNDO\', 213:content != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter have to be specified as an array/)
      end

      it "should not support a value that does not contain an assignment" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => 'contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
      end

      it "should not support a non-numeric metric number" do
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => '16x:contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => 'x16:contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => '1x6:contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => 'xyz:contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
        proc { described_class.new(:name => 'testdb', :type => :oracle, :home => '/home', :filter => ':contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
      end
    end

    describe "for filter_membership" do
      it "should support minimum" do
        proc { described_class.new(:name => "testdb", :type => :oracle, :home => '/home', :filter_membership => :minimum) }.should_not raise_error
      end


      it "should support inclusive" do
        proc { described_class.new(:name => "testdb", :type => :oracle, :home => '/home', :filter_membership => :inclusive) }.should_not raise_error
      end

      it "should use inclusive as the defaultvalue" do
        described_class.new(:name => 'testdb', :type => :oracle, :home => '/home')[:filter_membership].should == :inclusive
      end

      it "should not support other values" do
        proc { described_class.new(:name => "testdb", :type => :oracle, :home => '/home', :filter_membership => :minimal) }.should raise_error(Puppet::Error, /Invalid value/)
      end
    end

  end

  describe "when syncinc" do

    describe "property filter" do

      before :each do
        @provider = @provider_class.new(
          :name   => 'testdb',
          :ensure => :present,
          :home   => '/home',
          :type   => :oracle,
          :filter => {
            :'16'   => 'old_value',
            :'500'  => 'value_not_in_new_should'
          }
        )
        @resource = described_class.new(
          :name   => 'testdb',
          :ensure => :present,
          :home   => '/home',
          :type   => :oracle,
          :filter => [
            '16:contents != \'UNDO\'',
            '300:username == \'system\'',
          ],
          :provider => @provider
        )
        @property = @resource.parameter(:filter)
      end

      it "should send a hash to the provider" do
        @resource[:filter_membership] = :inclusive
        @provider.expects(:filter=).with(:'16' => 'contents != \'UNDO\'', :'300' => 'username == \'system\'')
        @property.sync
      end

      it "should merge the current values into should when minimum membership" do
        @resource[:filter_membership] = :minimum
        @provider.expects(:filter=).with(:'16' => 'contents != \'UNDO\'', :'300' => 'username == \'system\'',:'500' => 'value_not_in_new_should')
        @property.sync
      end

    end

  end

end
