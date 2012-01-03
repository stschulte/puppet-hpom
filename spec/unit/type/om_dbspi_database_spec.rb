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

    [:ensure, :username, :password, :logfile, :filter ].each do |property|
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
        proc { described_class.new(:name => 'TestDB', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'TEST01', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'Test_DB', :ensure => :present) }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { described_class.new(:name => 'test db', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => 'testdb ', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => ' testdb', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { described_class.new(:name => "test\tdb", :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
      end

      it "should not support an empty name" do
        proc { described_class.new(:name => '', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*empty/)
      end
    end

    describe "for username" do
      it "should support a valid name" do
        proc { described_class.new(:name => 'testdb', :username => 'itouser', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :username => 'sys', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :username => 'system', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :username => 'my_fancy_user', :ensure => :present) }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { described_class.new(:name => 'testdb', :username => 'my user', :ensure => :present) }.should raise_error(Puppet::Error, /Username.*whitespace/)
        proc { described_class.new(:name => 'testdb', :username => ' myuser', :ensure => :present) }.should raise_error(Puppet::Error, /Username.*whitespace/)
        proc { described_class.new(:name => 'testdb', :username => 'myuser ', :ensure => :present) }.should raise_error(Puppet::Error, /Username.*whitespace/)
        proc { described_class.new(:name => 'testdb', :username => "my\tuser", :ensure => :present) }.should raise_error(Puppet::Error, /Username.*whitespace/)
      end
    end

    describe "for password" do
      it "should support a valid password" do
        proc { described_class.new(:name => 'testdb', :password => 'myfancepw', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :password => 'myfan123!cepw', :ensure => :present) }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { described_class.new(:name => 'testdb', :password => 'my pw', :ensure => :present) }.should raise_error(Puppet::Error, /Password.*whitespace/)
        proc { described_class.new(:name => 'testdb', :password => 'mypw ', :ensure => :present) }.should raise_error(Puppet::Error, /Password.*whitespace/)
        proc { described_class.new(:name => 'testdb', :password => ' mypw', :ensure => :present) }.should raise_error(Puppet::Error, /Password.*whitespace/)
        proc { described_class.new(:name => 'testdb', :password => "my\tpw", :ensure => :present) }.should raise_error(Puppet::Error, /Password.*whitespace/)
      end
    end

    describe "for logfile" do
      it "should support a valid path" do
        proc { described_class.new(:name => 'testdb', :logfile => '/u01/testdb/alert.log', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :logfile => '/u01/foo_bar/alert.log', :ensure => :present) }.should_not raise_error
        proc { described_class.new(:name => 'testdb', :logfile => '/alert.log', :ensure => :present) }.should_not raise_error
      end

      it "should not support a relative path" do
        proc { described_class.new(:name => 'testdb', :logfile => 'testdb/alert.log', :ensure => :present) }.should raise_error(Puppet::Error, /Logfile must be an absolute path/)
      end
    end

    describe "for filter" do
      it "should support a single assignment" do
        proc { described_class.new(:name => 'testdb', :filter => '16:contents != \'UNDO\'', :ensure => :present) }.should_not raise_error
      end

      it "should support multiple filter definitions as an array" do
        proc { described_class.new(:name => 'testdb', :filter => ['16:contents != \'UNDO\'', '213:content != \'UNDO\''], :ensure => :present) }.should_not raise_error
      end

      it "should not support a comma separated list" do
        proc { described_class.new(:name => 'testdb', :filter => '16:contents != \'UNDO\', 213:content != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter have to be specified as an array/)
      end

      it "should not support a value that does not contain an assignment" do
        proc { described_class.new(:name => 'testdb', :filter => 'contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
      end

      it "should not support a non-numeric metric number" do
        proc { described_class.new(:name => 'testdb', :filter => '16x:contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
        proc { described_class.new(:name => 'testdb', :filter => 'x16:contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
        proc { described_class.new(:name => 'testdb', :filter => '1x6:contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
        proc { described_class.new(:name => 'testdb', :filter => 'xyz:contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
        proc { described_class.new(:name => 'testdb', :filter => ':contents != \'UNDO\'', :ensure => :present) }.should raise_error(Puppet::Error, /Filter must be of the form.*/)
      end
    end

    describe "for filter_membership" do
      it "should support minimum" do
        proc { described_class.new(:name => "testdb", :filter_membership => :minimum) }.should_not raise_error
      end


      it "should support inclusive" do
        proc { described_class.new(:name => "testdb", :filter_membership => :inclusive) }.should_not raise_error
      end

      it "should use inclusive as the defaultvalue" do
        described_class.new(:name => 'testdb')[:filter_membership].should == :inclusive
      end

      it "should not support other values" do
        proc { described_class.new(:name => "testdb", :filter_membership => :minimal) }.should raise_error(Puppet::Error, /Invalid value/)
      end
    end

  end

  describe "when syncinc" do

    describe "property filter" do

      before :each do
        @provider = @provider_class.new(
          :name   => 'testdb',
          :ensure => :present,
          :filter => {
            :'16'   => 'old_value',
            :'500'  => 'value_not_in_new_should'
          }
        )
        @resource = described_class.new(
          :name   => 'testdb',
          :ensure => :present,
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
