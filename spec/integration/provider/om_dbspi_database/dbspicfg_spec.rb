#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_dbspi_database).provider(:dbspicfg), '(integration)' do

  before :each do
    described_class.stubs(:command).with(:dbspicfg).returns '/var/opt/OV/bin/instrumentation/dbspicfg'
    described_class.stubs(:suitable?).returns true
    described_class.stubs(:dbspicfg).with('-e').returns File.read(my_fixture('input'))
    Puppet::Type::Om_dbspi_database.stubs(:defaultprovider).returns described_class

    @tempfile_path = nil
    @new_config = nil
    Puppet::Util::ExecutionStub.set do |command,options|
      if command == ['/var/opt/OV/bin/instrumentation/dbspicfg', '-i']
        @tempfile_path = options[:stdinfile]
        @new_config = File.read(@tempfile_path)
      else
        fail "Unexpected command #{command.inspect} executed"
      end
    end
  end

  after :each do
    unless @tempfile_path.nil?
      File.exists?(@tempfile_path).should be_false
    end
    described_class.initvars
  end

  def run_in_catalog(*resources)
    catalog = Puppet::Resource::Catalog.new
    catalog.host_config = false
    resources.each do |resource|
      resource.expects(:err).never
      catalog.add_resource(resource)
    end
    catalog.apply
  end

  describe "when database is should be absent" do

    it "should do nothing if database is already absent" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name   => 'NO_SUCH_DATABASE',
        :ensure => :absent
      )
      run_in_catalog(resource)
      @new_config.should be_nil # dbspicfg is never called
    end

    it "should be able to remove a database" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name   => 'SIMPLE',
        :ensure => :absent
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_remove_one_simple'))
    end

    it "should be able to remove a database with logfile and filter" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name   => 'OMLE',
        :ensure => :absent
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_remove_one_complex'))
    end

    it "should remove the home section if no databases are left" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name   => 'FOO',
        :ensure => :absent
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_remove_one_with_home'))
    end

  end

  describe "when database is absent and should be present" do

    it "should be able to create a database" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'SIMPLE2',
        :connect => 'itouser/secret@host:1521/SIMPLE2',
        :type    => :oracle,
        :home    => '/u01/app/oracle/product/11.2.0/dbhome_1'
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_add_simple'))
    end

    it "should be able to create a database with logfile and filter" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'COMPLEX',
        :connect => 'itouser/secret@host:1521/COMPLEX',
        :type    => :oracle,
        :home    => '/u01/app/oracle/product/11.2.0/dbhome_2',
        :logfile => '/u01/app/oracle/diag/rdbms/complex/COMPLEX/trace/alert_COMPLEX.log',
        :filter  => [
          '10:filter 10',
          '2:filter 2',
          '15:filter 15'
        ]
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_add_complex'))
    end

    it "should begin a new database type section if database adds a new type" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'COMPLEX',
        :connect => 'itouser/secret@host:1521/COMPLEX',
        :type    => :informix,
        :home    => '/u01/app/oracle/product/11.2.0/dbhome_2',
        :logfile => '/u01/app/oracle/diag/rdbms/complex/COMPLEX/trace/alert_COMPLEX.log',
        :filter  => [
          '10:filter 10',
          '2:filter 2',
          '15:filter 15'
        ]
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_add_new_type'))
    end

    it "should begin a new home section if database adds a new home" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'COMPLEX',
        :connect => 'itouser/secret@host:1521/COMPLEX',
        :type    => :oracle,
        :home    => '/u01/app/oracle/product/11.2.0/dbhome_3',
        :logfile => '/u01/app/oracle/diag/rdbms/complex/COMPLEX/trace/alert_COMPLEX.log',
        :filter  => [
          '10:filter 10',
          '2:filter 2',
          '15:filter 15'
        ]
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_add_new_home'))
    end

  end

  describe "when home is out of sync" do
    it "should move database in new home section" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name => 'OMLP',
        :home => '/u01/app/oracle/product/11.2.0/dbhome_2'
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_sync_home'))
    end
  end

  describe "when connect is out of sync" do
    it "should change the connect string" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'OMLE',
        :connect => 'itouser/freaking_new_password@host:1521/OMLE',
        :type    => :oracle,
        :home    => '/u01/app/oracle/product/11.2.0/dbhome_1'
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_sync_connect'))
    end
  end

  describe "when database type is out of sync" do
    it "should move database in new database type section" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name => 'FOO',
        :type => :informix,
        :home => '/u01/app/oracle/product/11.2.0/dbhome_2'
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_sync_type'))
    end

  end

  describe "when logfile is out of sync" do
    it "should change logfile" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'OMLE',
        :logfile => '/newpath/alert.log',
        :home    => '/u01/app/oracle/product/11.2.0/dbhome_1',
        :type    => :oracle
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_sync_logfile'))
    end

  end

  describe "when filters are out of sync" do
    it "should only add new filter with membership minimum" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name              => 'OMLE',
        :type              => :oracle,
        :home              => '/u01/app/oracle/product/11.2.0/dbhome_1',
        :filter            => ['18:new filter','19:new filter2'],
        :filter_membership => :minimum
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_sync_filter_add'))
    end

    it "should remove filter with membership inclusive" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name              => 'OMLE',
        :type              => :oracle,
        :home              => '/u01/app/oracle/product/11.2.0/dbhome_1',
        :filter            => [],
        :filter_membership => :inclusive
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_sync_filter_remove'))
    end

    it "should change filter" do
      resource = Puppet::Type.type(:om_dbspi_database).new(
        :name              => 'FOO',
        :type              => :oracle,
        :home              => '/u01/app/oracle/product/11.2.0/dbhome_2',
        :filter            => [
          '201:changed',
          '300:added'
        ]
      )
      run_in_catalog(resource)
      @new_config.should == File.read(my_fixture('output_sync_filter_change'))
    end
  end

  describe "when multiple resources are in the catalog" do
    it "should do the right thing (tm)" do
      resources = []
      resources << Puppet::Type.type(:om_dbspi_database).new(
        :name   => 'FOO',
        :ensure => :absent
      )
      resources << Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'SIMPLE',
        :ensure  => :present,
        :type    => :informix,
        :home    => '/u01/app/oracle/product/11.2.0/dbhome_1',
        :logfile => '/new/simple/logfile',
        :filter  => [
          '100:new filter 100',
          '110:new filter 110'
        ]
      )
      resources << Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'OMLE',
        :ensure  => :present,
        :type    => :oracle,
        :logfile => '/changed/location/for/OMLE',
        :home    => '/new/home/special/for/OMLE',
        :filter  => [
          '16:tablespace_name not in (select tablespace_name from dba_tablespaces where contents = \'UNDO\')',
          '17:new filter'
        ]
      )
      resources << Puppet::Type.type(:om_dbspi_database).new(
        :name    => 'OMLP',
        :ensure  => :present,
        :type    => :oracle,
        :home    => '/u01/app/oracle/product/11.2.0/dbhome_1',
        :connect => 'new_connect',
        :filter  => []
      )
      described_class.stubs(:dbspicfg).with('-e').returns File.read(my_fixture('input_with_listener'))
      run_in_catalog(*resources)
      @new_config.should == File.read(my_fixture('output_multiplechanges'))
    end
  end

end
