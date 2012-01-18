#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/file_bucket/dipper'

describe Puppet::Type.type(:om_dbspi_option).provider(:parsed), '(integration)' do
  include PuppetSpec::Files

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:om_dbspi_option).stubs(:defaultprovider).returns described_class

    @fake_defaults = tmpfile('om_dbspi_option_test')
    FileUtils.cp(my_fixture('input'), @fake_defaults)
    described_class.stubs(:default_target).returns @fake_defaults

    @resource_absent = Puppet::Type.type(:om_dbspi_option).new(
      :name   => 'FOOBAR',
      :ensure => :absent
    )
    @resource_present = Puppet::Type.type(:om_dbspi_option).new(
      :name   => 'ORA_0X16_REPORT_DETAILS',
      :value  => 'OFF',
      :ensure => :present
    )
    @resource_create = Puppet::Type.type(:om_dbspi_option).new(
      :name   => 'ORA_X16_VIEWS',
      :value  => 'ON',
      :ensure => :present
    )
    @resource_remove = Puppet::Type.type(:om_dbspi_option).new(
      :name   => 'DATABASE02',
      :ensure => :absent
    )
    @resource_sync01 = Puppet::Type.type(:om_dbspi_option).new(
      :name   => 'DATABASE03',
      :value  => 'ON',
      :ensure => :present
    )
    @resource_sync02 = Puppet::Type.type(:om_dbspi_option).new(
      :name   => 'ORA_LOW_LEVEL_SEGMENT_QUERY',
      :value  => 'ON',
      :ensure => :present
    )
  end

  after :each do
    described_class.clear
  end

  def run_in_catalog(*resources)
    Puppet::FileBucket::Dipper.any_instance.stubs(:backup) # Don't backup to filebucket
    catalog = Puppet::Resource::Catalog.new
    catalog.host_config = false
    resources.each do |resource|
      resource.expects(:err).never
      catalog.add_resource(resource)
    end
    catalog.apply
  end

  def check_content_against(fixture)
    content = File.read(@fake_defaults).lines.map{|l| l.chomp}.reject{|l| l=~ /^\s*#|^\s*$/}.sort.join("\n")
    expected_content = File.read(my_fixture(fixture)).lines.map{|l| l.chomp}.reject{|l| l=~ /^\s*#|^\s*$/}.sort.join("\n")
    content.should == expected_content
  end

  describe "when managing one resource" do

    describe "with ensure set to absent" do

      it "should do nothing if already absent" do
        run_in_catalog(@resource_absent)
        check_content_against('input')
      end

      it "shoule remove option if currently present" do
        run_in_catalog(@resource_remove)
        check_content_against('output_one_remove')
      end

    end

    describe "with ensure set to present" do

      it "should do nothing if already present and in sync" do
        run_in_catalog(@resource_present)
        check_content_against('input')
      end

      it "should sync value if out of sync" do
        run_in_catalog(@resource_sync01)
        check_content_against('output_one_sync')
      end

      it "should create option if currently absent" do
        run_in_catalog(@resource_create)
        check_content_against('output_one_create')
      end

    end

  end

  describe "when managing multiple resources" do

    it "should do the right thing (tm)" do
      run_in_catalog(
        @resource_present,
        @resource_absent,
        @resource_create,
        @resource_remove,
        @resource_sync01,
        @resource_sync02
      )
      check_content_against('output_multiple')
    end

  end

end
