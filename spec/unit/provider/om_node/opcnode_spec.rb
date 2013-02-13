#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_node).provider(:opcnode) do

  let(:sample_output) do
    fakeoutput = my_fixture('opcnodehelper_output')
    File.read(fakeoutput)
  end

  before :each do
    described_class.stubs(:suitable).returns true
    Puppet::Type.type(:om_node).stubs(:defaultprovider).returns described_class

    @resource = Puppet::Type.type(:om_node).new(
      :name               => 'host.example.com',
      :label              => 'host',
      :dynamic_ip         => :no,
      :network_type       => :NETWORK_IP,
      :node_type          => :MONITORED,
      :machine_type       => :MACH_BBC_LX26RPM_X64,
      :communication_type => :COMM_BBC,
      :node_groups        => ['g2','g4','g5'],
      :layout_groups      => ['/Hier1/Group1','/Hier2/Group2','/Hier3/Group3','/Hier4/Group4']
    )
  end

  it "should support prefetching" do
    described_class.should respond_to :prefetch
  end

  it "should support instances" do
    described_class.should respond_to :instances
  end

  it "should support create" do
    described_class.new(@resource).should respond_to :create
  end

  it "should support destroy" do
    described_class.new(@resource).should respond_to :destroy
  end

  it "should support exists?" do
    described_class.new(@resource).should respond_to :exists?
  end

  [:label, :ipaddress, :network_type, :machine_type, :communication_type, :node_type, :dynamic_ip, :layout_groups, :node_groups].each do |property|
    it "should have getter and setter for property #{property}" do
      described_class.new(@resource).should respond_to property
      described_class.new(@resource).should respond_to "#{property}=".intern
    end
  end


  describe "when calling instances" do

    before :each do
      described_class.stubs(:nodehelper).returns sample_output
    end

    it "should not raise an error on valid output" do
      proc { described_class.instances }.should_not raise_error
    end

    it "should detect two nodes" do
      described_class.instances.size.should == 2
    end

    describe "when node is in multiple hierarchies and groups" do

      before :each do
        @instances = described_class.instances
      end

      it "should be able to parse name correctly" do
        @instances[0].get(:name).should == 'host1.example.com'
      end

      it "should be able to parse label correctly" do
        @instances[0].get(:label).should == 'host1'
      end

      it "should be able to parse ipaddress correctly" do
        @instances[0].get(:ipaddress).should == '10.0.0.1'
      end

      it "should be able to parse network_type" do
        @instances[0].get(:network_type).should == :NETWORK_IP
      end

      it "should be able to parse machine_type" do
        @instances[0].get(:machine_type).should == :MACH_BBC_SOL10_X86
      end

      it "should be able to parse communication_type" do
        @instances[0].get(:communication_type).should == :COMM_BBC
      end

      it "should be able to parse node_type" do
        @instances[0].get(:node_type).should == :MONITORED
      end

      it "should be able to parse dynamic_ip" do
        @instances[0].get(:dynamic_ip).should == :no
      end

      it "should be able to parse layout_groups" do
        @instances[0].get(:layout_groups).should == {:NodeBank => 'Unix',:Hier1 => 'Solaris/Intel'}
      end

      it "should be able to parse node_groups" do
        @instances[0].get(:node_groups).should == 'M-Solaris,M-SAP'
      end

      it "should set ensure to present" do
        @instances[0].get(:ensure).should == :present
      end

    end

    describe "when node is in no hierarchie or group" do

      before :each do
        @instances = described_class.instances
      end

      it "should be able to parse name correctly" do
        @instances[1].get(:name).should == 'router.example.com'
      end

      it "should be able to parse label correctly" do
        @instances[1].get(:label).should == 'router'
      end

      it "should be able to parse ipaddress correctly" do
        @instances[1].get(:ipaddress).should == '0.0.0.0'
      end

      it "should be able to parse network_type" do
        @instances[1].get(:network_type).should == :PATTERN_IP_NAME
      end

      it "should be able to parse machine_type" do
        @instances[1].get(:machine_type).should == :MACH_OTHER
      end

      it "should be able to parse communication_type" do
        @instances[1].get(:communication_type).should == :COMM_UNSPEC_COMM
      end

      it "should be able to parse dynamic_ip" do
        @instances[1].get(:dynamic_ip).should == :no
      end

      it "should be able to parse layout_groups" do
        @instances[1].get(:layout_groups).should == {}
      end

      it "should be able to parse node_groups" do
        @instances[1].get(:node_groups).should == ''
      end

      it "should set ensure to present" do
        @instances[1].get(:ensure).should == :present
      end

    end

  end

  describe "when destroying a node" do

    it "should use del_node to delete a node" do
      @provider = described_class.new(Puppet::Type.type(:om_node).new(:name => 'host.example.com'))
      @provider.expects(:opcnode).with('-del_node','node_name=host.example.com')
      @provider.destroy
    end

    it "should pass net_type if available" do
      @provider = described_class.new(Puppet::Type.type(:om_node).new(:name => 'host.example.com'))
      @provider.set(
        :name              => 'host.example.com',
        :label             => 'host',
        :ipaddress         => '10.0.0.1',
        :network_type      => :NETWORK_IP,
        :commuication_type => :COMM_BBC,
        :machine_type      => :MACH_BBC_SOL10_X86,
        :node_type         => :MONITORED,
        :dynamic_ip        => :no,
        :layout_groups     => {:NodeBank => 'Unix',:Hier1 => 'Solaris/Intel'}
      )

      @provider.expects(:opcnode).with('-del_node','node_name=host.example.com','net_type=NETWORK_IP')
      @provider.destroy
    end

  end

  describe "when creating a new node" do

    def example_provider(optional_properties = {})
      default_properties = {:name => 'host.example.com', :node_groups => 'foo'}
      described_class.new(Puppet::Type.type(:om_node).new(default_properties.merge(optional_properties)))
    end

    def example_arguments(*optional_arguments)
      ['-add_node','node_name=host.example.com' ] + optional_arguments + [ 'group_name=foo' ]
    end

    before :each do
      # deactivate default values for now...
      [:ensure, :label, :ipaddress, :network_type, :machine_type, :communication_type, :node_type, :dynamic_ip, :layout_groups, :node_groups,].each do |property|
        Puppet::Type.type(:om_node).attrclass(property).stubs(:method_defined?).with(:default).returns(false)
      end
    end

    it "should pass the node_name to the command" do
      @provider = example_provider
      @provider.expects(:opcnode).with *example_arguments
      @provider.create
    end

    it "should fail with no node_groups" do
      @provider = described_class.new(Puppet::Type.type(:om_node).new(:name => 'host.example.com'))
      proc { @provider.create }.should raise_error(Puppet::Error, /Cannot create.*no node_groups set/)
    end

    it "should fail with an empty node_groups" do
      @provider = example_provider(:node_groups => [])
      proc { @provider.create }.should raise_error(Puppet::Error, /Cannot create.*no node_groups set/)
    end

    it "should pass a single node_group with group_name" do
      @provider = described_class.new(Puppet::Type.type(:om_node).new(:name => 'host.example.com',:node_groups => 'foo'))
      @provider.expects(:opcnode).with('-add_node','node_name=host.example.com', 'group_name=foo')
      @provider.expects(:opcnode).with{|*args| args.include?('-assign_node')}.never
      @provider.create
    end

    it "should pass the first node_group to add_node and assign the rest later" do
      @provider = described_class.new(Puppet::Type.type(:om_node).new(:name => 'host.example.com',:node_groups => ['foo','bar','baz','faz']))
      @provider.expects(:opcnode).with('-add_node','node_name=host.example.com', 'group_name=bar') # (the list is getting sorted)
      @provider.expects(:opcnode).with('-assign_node','node_name=host.example.com','group_name=bar').never
      @provider.expects(:opcnode).with('-assign_node','node_name=host.example.com','group_name=baz').once
      @provider.expects(:opcnode).with('-assign_node','node_name=host.example.com','group_name=foo').once
      @provider.expects(:opcnode).with('-assign_node','node_name=host.example.com','group_name=faz').once
      @provider.create
    end

    it "should set net_type during group assignments if available" do
      @provider = described_class.new(Puppet::Type.type(:om_node).new(
        :name         => 'host.example.com',
        :node_groups => ['foo','bar','baz','faz'],
        :network_type => :NETWORK_IP
      ))
      @provider.expects(:opcnode).with{ |*args| args.include? '-add_node'}.once
      @provider.expects(:opcnode).with{ |*args| args.include? '-assign_node' and args.include? 'net_type=NETWORK_IP' }.times(3)
      @provider.expects(:opcnode).with{ |*args| args.include? '-assign_node' and !args.include? 'net_type=NETWORK_IP' }.never
      @provider.create
    end

    it "should pass the node_label if available" do
      @provider = example_provider(:label => 'host')
      @provider.expects(:opcnode).with *example_arguments('node_label=host')
      @provider.create
    end

    it "should pass ip_addr if available" do
      @provider = example_provider(:ipaddress => '192.168.0.1')
      @provider.expects(:opcnode).with *example_arguments('ip_addr=192.168.0.1')
      @provider.create
    end

    it "should pass net_type if available" do
      @provider = example_provider(:network_type => :NETWORK_IP)
      @provider.expects(:opcnode).with *example_arguments('net_type=NETWORK_IP')
      @provider.create
    end

    it "should pass mach_type if available" do
      @provider = example_provider(:machine_type => :MACH_BBC_LX26RPM_X64)
      @provider.expects(:opcnode).with *example_arguments('mach_type=MACH_BBC_LX26RPM_X64')
      @provider.create
    end

    it "should pass comm_type if available" do
      @provider = example_provider(:communication_type => :COMM_BBC)
      @provider.expects(:opcnode).with *example_arguments('comm_type=COMM_BBC')
      @provider.create
    end

    it "should pass node_type if available" do
      @provider = example_provider(:node_type => :CONTROLLED)
      @provider.expects(:opcnode).with *example_arguments('node_type=CONTROLLED')
      @provider.create
    end

    it "should pass dynamic_ip if available" do
      @provider = example_provider(:dynamic_ip => :true)
      @provider.expects(:opcnode).with *example_arguments('dynamic_ip=yes')
      @provider.create
    end

    it "should not move node after creation if no layout_groups specified" do
      @provider = example_provider
      @provider.expects(:opcnode).with(*example_arguments).once
      @provider.expects(:opcnode).with{|*args| args.include? '-move_nodes'}.never
      @provider.create
    end

    it "should not move node after creation if layout_groups is empty" do
      @provider = example_provider(:layout_groups => [])
      @provider.expects(:opcnode).with(*example_arguments).once
      @provider.expects(:opcnode).with{|*args| args.include? '-move_nodes'}.never
      @provider.create
    end

    it "should move node after creation if layout_groups specified" do
      @provider = example_provider(:layout_groups => '/Hier1/Group1a/Group1b')
      @provider.expects(:opcnode).with(*example_arguments).once
      @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier1','layout_group=Group1a/Group1b')
      @provider.create
    end

    it "should move to multiple layout groups if array specified" do
      @provider = example_provider(:layout_groups => ['/Hier1/Group1a/Group1b','/Hier2/Group2a'])
      @provider.expects(:opcnode).with(*example_arguments).once
      @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier1','layout_group=Group1a/Group1b').once
      @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier2','layout_group=Group2a').once
      @provider.create
    end

    it "should pass net_type if available" do
      @provider = example_provider(:layout_groups => ['/Hier1/Group1a/Group1b','/Hier2/Group2a'], :network_type => :NETWORK_IP)
      @provider.expects(:opcnode).with(*example_arguments('net_type=NETWORK_IP')).once
      @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier1','layout_group=Group1a/Group1b','net_type=NETWORK_IP')
      @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier2','layout_group=Group2a','net_type=NETWORK_IP')
      @provider.create
    end

  end

  describe "when modifying attribute" do

    describe "communication_type" do

      it "should use chg_commtype" do
        @provider = described_class.new(:name => 'host.example.com', :communication_type => :COMM_DCE_UDP)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-chg_commtype','node_name=host.example.com','comm_type=COMM_BBC')
        @provider.communication_type = @resource[:communication_type]
      end

      it "should pass net_type if available" do
        @provider = described_class.new(:name => 'host.example.com', :communication_type => :COMM_DCE_UDP ,:network_type => :NETWORK_IP)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-chg_commtype','node_name=host.example.com','net_type=NETWORK_IP','comm_type=COMM_BBC')
        @provider.communication_type = @resource[:communication_type]
      end

    end

    describe "machine_type" do

      it "should use chg_machtype" do
        @provider = described_class.new(:name => 'host.example.com', :machine_type => :MACH_BBC_WIN2K3_X64)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-chg_machtype','node_name=host.example.com','mach_type=MACH_BBC_LX26RPM_X64')
        @provider.machine_type = @resource[:machine_type]
      end

      it "should never pass net_type" do
        @provider = described_class.new(:name => 'host.example.com', :machine_type => :MACH_BBC_WIN2K3_X64, :network_type => :NETWORK_IP)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-chg_machtype','node_name=host.example.com','mach_type=MACH_BBC_LX26RPM_X64')
        @provider.machine_type = @resource[:machine_type]
      end

    end

    describe "node_type" do

      it "should use chg_nodetype" do
        @provider = described_class.new(:name => 'host.example.com', :node_type => :CONTROLLED)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-chg_nodetype','node_name=host.example.com','node_type=MONITORED')
        @provider.node_type = @resource[:node_type]
      end

      it "should pass net_type if available" do
        @provider = described_class.new(:name => 'host.example.com', :network_type => :NETWORK_IP, :node_type => :CONTROLLED)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-chg_nodetype','node_name=host.example.com','net_type=NETWORK_IP','node_type=MONITORED')
        @provider.node_type = @resource[:node_type]
      end

    end

    describe "layout groups" do

      it "should only move to additional or changed layout_groups" do
        @provider = described_class.new(:name => 'host.example.com', :layout_groups => {:Hier1 => 'Group1',:Hier3 => 'Wrong'})
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier1','layout_group=Group1').never
        @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier2','layout_group=Group2').once
        @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier3','layout_group=Group3').once
        @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier4','layout_group=Group4').once
        @provider.layout_groups = @resource[:layout_groups]
      end

      it "should pass net_type if available" do
        @provider = described_class.new(:name => 'host.example.com', :layout_groups => {:Hier1 => 'Group1',:Hier3 => 'Group3'}, :network_type => :NETWORK_IP)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier1','layout_group=Group1','net_type=NETWORK_IP').never
        @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier2','layout_group=Group2','net_type=NETWORK_IP').once
        @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier3','layout_group=Group3','net_type=NETWORK_IP').never
        @provider.expects(:opcnode).with('-move_nodes','node_list=host.example.com','node_hier=Hier4','layout_group=Group4','net_type=NETWORK_IP').once
        @provider.layout_groups = @resource[:layout_groups]
      end

    end

    describe "dynamic_ip" do

      it "should use chg_iptype" do
        @provider = described_class.new(:name => 'host.example.com',:dynamic_ip => :yes)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-chg_iptype','node_name=host.example.com','dynamic_ip=no')
        @provider.dynamic_ip = @resource[:dynamic_ip]
      end

      it "should never pass net_type" do
        @provider = described_class.new(:name => 'host.example.com', :network_type => :NETWORK_IP, :dynamic_ip => :yes)
        @resource.provider = @provider
        @provider.expects(:opcnode).with('-chg_iptype','node_name=host.example.com','dynamic_ip=no')
        @provider.dynamic_ip = @resource[:dynamic_ip]
      end

    end

    describe "node_groups" do

      it "should add new groups and delete old groups" do
        @provider = described_class.new(:name => 'host.example.com', :node_groups => 'g1,g2,g3')
        @resource.provider = @provider

        @provider.expects(:opcnode).with('-assign_node','node_name=host.example.com','group_name=g4').once
        @provider.expects(:opcnode).with('-assign_node','node_name=host.example.com','group_name=g5').once
        @provider.expects(:opcnode).with('-deassign_node','node_name=host.example.com','group_name=g1').once
        @provider.expects(:opcnode).with('-deassign_node','node_name=host.example.com','group_name=g3').once

        @provider.node_groups = @resource[:node_groups]
      end

      it "should pass net_type if available" do
        @provider = described_class.new(:name => 'host.example.com', :node_groups => 'g1,g2,g3',:network_type => :NETWORK_IP)
        Puppet::Type.type(:om_node).new(:name => 'host.example.com', :node_groups => ['g2','g4','g5']).provider = @provider

        @provider.expects(:opcnode).with('-assign_node','node_name=host.example.com','group_name=g4','net_type=NETWORK_IP').once
        @provider.expects(:opcnode).with('-assign_node','node_name=host.example.com','group_name=g5','net_type=NETWORK_IP').once
        @provider.expects(:opcnode).with('-deassign_node','node_name=host.example.com','group_name=g1','net_type=NETWORK_IP').once
        @provider.expects(:opcnode).with('-deassign_node','node_name=host.example.com','group_name=g3','net_type=NETWORK_IP').once

        @provider.node_groups = 'g2,g4,g5'
      end

    end

    [:network_type, :label, :ipaddress].each do |property|
      describe "#{property}" do

        it "should not support editing #{property}" do
          @provider = described_class.new(:name => 'host.example.com')
          @resource.provider = @provider
          proc { @provider.send("#{property}=",'foo') }.should raise_error(Puppet::Error, /#{property}.*not supported/)
        end

      end
    end

  end

end
