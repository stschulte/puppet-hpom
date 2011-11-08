#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_node) do

  before do
    @class = described_class
    @provider_class = @class.provide(:fake) { mk_resource_methods }
    @provider_class.stubs(:suitable).returns true
    @class.stubs(:defaultprovider).returns @provider_class
  end

  it "should have :name as its keyattribute" do
    @class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do

    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        @class.attrtype(param).should == :param
      end
    end

    [:ensure, :label, :ipaddress, :network_type, :machine_type, :communication_type, :node_type, :dynamic_ip, :layout_groups, :node_groups,].each do |property|
      it "should have a #{property} property" do
        @class.attrtype(property).should == :property
      end
    end

  end

  describe "when validating value" do

    describe "for ensure" do

      it "should support present" do
        proc { @class.new(:name => 'foo', :ensure => :present) }.should_not raise_error
      end

      it "should support absent" do
        proc { @class.new(:name => 'foo', :ensure => :absent) }.should_not raise_error
      end

      it "should not support other values" do
        proc { @class.new(:name => 'foo', :ensure => :foo) }.should raise_error(Puppet::Error, /Invalid value/)
      end


    end

    describe "for name" do

      it "should support a valid name" do
        proc { @class.new(:name => 'test.example.com', :ensure => :present) }.should_not raise_error
        proc { @class.new(:name => 'test', :ensure => :present) }.should_not raise_error
        proc { @class.new(:name => '10.99.1.1', :ensure => :present) }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { @class.new(:name => 'test com', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { @class.new(:name => 'testcom ', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { @class.new(:name => ' testcom', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
        proc { @class.new(:name => "test\tcom", :ensure => :present) }.should raise_error(Puppet::Error, /Name.*whitespace/)
      end

      it "should not support an empty name" do
        proc { @class.new(:name => '', :ensure => :present) }.should raise_error(Puppet::Error, /Name.*empty/)
      end

    end

    describe "for label" do

      it "should support a simple label" do
        proc { @class.new(:name => 'test.example.com', :label => 'test', :ensure => :present) }.should_not raise_error
      end

      it "should support spaces in label" do
        proc { @class.new(:name => 'test.example.com', :label => 'my test', :ensure => :present) }.should_not raise_error
      end

    end

    describe "for ipaddress" do

      it "should support an ipv4 address" do
        proc { @class.new(:name => 'test.example.com', :ipaddress => '10.96.0.1') }.should_not raise_error
      end

      it "should support an ipv6 address" do
        proc { @class.new(:name => 'test.example.com', :ipaddress => '2001:0db8:85a3:08d3:1319:8a2e:0370:7344') }.should_not raise_error
      end

      it "should support a shortened ipv6 address" do
        proc { @class.new(:name => 'test.example.com', :ipaddress => '::ffff:192.0.2.128') }.should_not raise_error
        proc { @class.new(:name => 'test.example.com', :ipaddress => '2001:db8:0:8d3:0:8a2e:70:7344') }.should_not raise_error
        proc { @class.new(:name => 'test.example.com', :ipaddress => '::1') }.should_not raise_error
      end


      it "should not support malformed ipv4 addresses" do
        proc { @class.new(:name => 'test.example.com', :ipaddress => '192.168.0.300') }.should raise_error(Puppet::Error, /Invalid ip/)
      end

      it "should not support malformed ipv6 addresses" do
        proc { @class.new(:name => 'test.example.com', :ipaddress => '2001:0dg8:85a3:08d3:1319:8a2e:0370:7344') }.should raise_error(Puppet::Error, /Invalid ip/)
      end

    end

    describe "network_type" do

      [:NETWORK_NO_NODE, :NETWORK_IP, :NETWORK_OTHER, :NETWORK_UNKNOWN, :PATTERN_IP_ADDR, :PATTERN_IP_NAME, :PATTERN_OTHER].each do |type|
        it "should support #{type}" do
          proc { @class.new(:name => 'test.example.com', :network_type => type) }.should_not raise_error
        end
      end

      it "should not support anything else" do
        proc { @class.new(:name => 'test.example', :network_type => :foo) }.should raise_error(Puppet::Error, /Invalid value/)
      end

      it "should default to NETWORK_IP" do
        @class.new(:name => 'test.example')[:network_type].should == :NETWORK_IP
      end

    end

    describe "machine_type" do

      [
        :MACH_BBC_LX26RPM_X64,
        :MACH_BBC_OTHER_IP,
        :MACH_BBC_SOL10_X86,
        :MACH_BBC_LX26RPM_IPF64,
        :MACH_BBC_LX26RPM_X86,
        :MACH_BBC_WINXP_IPF64,
        :MACH_BBC_OTHER_NON_IP,
        :MACH_BBC_LX26RPM_PPC,
        :MACH_BBC_HPUX_IPF32,
        :MACH_BBC_HPUX_PA_RISC,
        :MACH_BBC_AIX_K64_PPC,
        :MACH_BBC_AIX_PPC,
        :MACH_BBC_WIN2K3_X64,
        :MACH_BBC_WINNT_X86,
        :MACH_BBC_SOL_SPARC
      ].each do |type|
        it "should support #{type}" do
          proc { @class.new(:name => 'test.example.com', :machine_type => type) }.should_not raise_error
        end
      end

      it "should not support anything else" do
        proc { @class.new(:name => 'test.example.com', :machine_type => :foo) }.should raise_error(Puppet::Error, /Invalid value/)
      end

    end

    describe "communication_type" do
      [ :COMM_UNSPEC_COMM, :COMM_BBC ].each do |type|
        it "should support #{type}" do
          proc { @class.new(:name => 'test.example.com', :communication_type => type) }.should_not raise_error
        end

      end

      it "should not support anything else" do
        proc { @class.new(:name => 'test.example.com', :communication_type => :foo) }.should raise_error(Puppet::Error, /Invalid value/)
      end

      it "should default to BlackBoxCommunication (SSL)" do
        @class.new(:name => 'test.example.com')[:communication_type].should == :COMM_BBC
      end

    end

    describe "node_type" do
      [:DISABLED, :CONTROLLED, :MONITORED, :MESSAGE_ALLOWED].each do |type|
        it "should support #{type}" do
          proc { @class.new(:name => 'test.example.com', :node_type => type) }.should_not raise_error
        end
      end

      it "should not support anything else" do
        proc { @class.new(:name => 'test.example.com', :node_type => :foo) }.should raise_error(Puppet::Error, /Invalid value/)
      end

      it "should default to CONTROLLED" do
        @class.new(:name => 'test.example.com')[:node_type].should == :CONTROLLED
      end

    end

    describe "dynamic_ip" do

      it "should support yes" do
        proc { @class.new(:name => 'test.example.com', :dynamic_ip => :yes) }.should_not raise_error
      end

      it "should support no" do
        proc { @class.new(:name => 'test.example.com', :dynamic_ip => :no) }.should_not raise_error
      end

      it "should support true" do
        proc { @class.new(:name => 'test.example.com', :dynamic_ip => :true) }.should_not raise_error
      end

      it "should support false" do
        proc { @class.new(:name => 'test.example.com', :dynamic_ip => :false) }.should_not raise_error
      end

      it "should not support anything else" do
        proc { @class.new(:name => 'test.example.com', :dynamic_ip => :nein) }.should raise_error(Puppet::Error, /Invalid value/)
      end

      it "should alias true to yes" do
        @class.new(:name => 'test.example.com', :dynamic_ip => :true)[:dynamic_ip].should == :yes
      end

      it "should alias false to no" do
        @class.new(:name => 'test.example.com', :dynamic_ip => :false)[:dynamic_ip].should == :no
      end

    end

    describe "node_groups" do

      it "should support a single group" do
        proc { @class.new(:name => 'test.example.com', :node_groups => 'hpux') }.should_not raise_error
      end

      it "should support multiple groups as an array" do
        proc { @class.new(:name => 'test.example.com', :node_groups => ['hpux','db']) }.should_not raise_error
      end

      it "should not support a comma separated list" do
        proc { @class.new(:name => 'test.example.com', :node_groups => 'hpux,db') }.should raise_error(Puppet::Error, /have to be specified as an array/)
      end

    end

    describe "layout_groups" do

      it "should support a simple layoutgroup" do
        proc { @class.new(:name => 'test.example.com', :layout_groups => 'Solaris/SPARC') }.should_not raise_error
      end

      it "should default the node_hierarchy to NodeBank" do
        @class.new(:name => 'test.example.com', :layout_groups => 'Solaris/SPARC')[:layout_groups].should == {:NodeBank => 'Solaris/SPARC'}
      end

      it "should support a layoutgroup with explicit node hierarchy" do
        proc { @class.new(:name => 'test.example.com', :layout_groups => '/Custom/Solaris/SPARC') }.should_not raise_error
      end

      it "should support multiple node hierarchies" do
        proc { @class.new(:name => 'test.example.com', :layout_groups => ['Solaris/SPARC', '/Custom/Solaris/SPARC']) }.should_not raise_error
      end

      it "should not allow multiple assignments in same hierarchy" do
        proc { @class.new(:name => 'test.example.com', :layout_groups => ['/Custom/Unix', '/Custom/Solaris/SPARC']) }.should raise_error(Puppet::Error, /layout_groups.*multiple.*same hierarchy: Custom$/)
        proc { @class.new(:name => 'test.example.com', :layout_groups => ['Solaris/SPARC', '/NodeBank/Solaris/SPARC']) }.should raise_error(Puppet::Error,  /layout_groups.*multiple.*same hierarchy: NodeBank$/)
      end

      it "should not support a comma separated list" do
        proc { @class.new(:name => 'test.example.com', :layout_groups => 'Foo,/Custom/Solaris/SPARC') }.should raise_error(Puppet::Error, /have to be specified as an array/)
      end

    end

  end

  describe "when syncing" do

    describe "property node_groups" do

      before :each do
        @provider = @provider_class.new
        @resource = @class.new(:name => 'host.example.com', :ensure => :present, :provider => @provider, :node_groups => ['afoo','zfoo','bfoo'])
        @property = @resource.parameter(:node_groups)
      end

      it "should send to sorted joined array to the provider" do
        @provider.expects(:'node_groups=').with('afoo,bfoo,zfoo')
        @property.sync

      end

      it "should not care about the order of groups" do
        @property.insync?(%w{afoo zfoo bfoo}).should == true
        @property.insync?(%w{afoo bfoo zfoo}).should == true
        @property.insync?(%w{bfoo afoo zfoo}).should == true
        @property.insync?(%w{bfoo zfoo afoo}).should == true
        @property.insync?(%w{zfoo afoo bfoo}).should == true
        @property.insync?(%w{zfoo bfoo afoo}).should == true
      end

    end

    describe "property layout_groups" do

      before :each do
        @provider = @provider_class.new
        @resource = @class.new(:name => 'host.example.com', :ensure => :present, :provider => @provider,
          :layout_groups => ['foo/bar','/a/foo/bar','/b/baz']
        )
        @property = @resource.parameter(:layout_groups)
      end

      it "should send a hash to the provider" do
        @provider.expects(:'layout_groups=').with(:NodeBank => 'foo/bar', :a => 'foo/bar', :b => 'baz')
        @property.sync
      end

      it "should merge current node_hierarchies with desired node_hierarchies" do
        @provider.set(:layout_groups => {:a => 'old/one', :c => 'old/one'})
        @provider.expects(:'layout_groups=').with(:NodeBank => 'foo/bar', :a => 'foo/bar', :b => 'baz', :c => 'old/one')
        @property.sync
      end

    end

  end

end
