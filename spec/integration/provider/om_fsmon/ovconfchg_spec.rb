#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_fsmon).provider(:ovconfchg), '(integration)' do

  before :each do
    described_class.stubs(:ovconfget).with('eaagt','SpaceUtilWarningThreshold').returns(
      '80,/mnt/c=60,/tmp=100,/=90,/mnt/a=40,/unknown=80'
    )
    described_class.stubs(:ovconfget).with('eaagt','SpaceUtilMinorThreshold').returns(
      '85,/mnt/a=50,/tmp=100,/mnt/b=80,/unknown=85'
    )
    described_class.stubs(:ovconfget).with('eaagt','SpaceUtilMajorThreshold').returns(
      '90,/mnt/a=60,/tmp=100,/mnt/b=85,/mnt/c=92,/unknown=90'
    )
    described_class.stubs(:ovconfget).with('eaagt','SpaceUtilCriticalThreshold').returns(
      '95,/tmp=100,/mnt/c=99,/mnt/b=90,/mnt/x=90,/unknown=95'
    )
    described_class.stubs(:suitable?).returns true
    Puppet::Type::Om_fsmon.stubs(:defaultprovider).returns described_class

    @mnt_a = Puppet::Type::Om_fsmon.new(
      :name => '/mnt/a',
      :warning  => :absent, # should be removed
      :minor    => '50',    # stays the same
      :major    => '10',    # 40->10
      :critical => :absent  # stays absent
    )
    @mnt_b = Puppet::Type::Om_fsmon.new(
      :name    => '/mnt/b',
      :warning => '60',     # create
      :minor   => '90'      # change 80->90
    )
    @tmp = Puppet::Type::Om_fsmon.new(
      :name     => '/tmp',
      :warning  => :absent,
      :minor    => :absent,
      :major    => :absent,
      :critical => :absent
    )
    @mnt_new = Puppet::Type::Om_fsmon.new(
      :name     => '/mnt/new',
      :warning  => '10',
      :critical => '20'
    )
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

  describe "when managing one resource" do

    it "should change an existing entry" do
      described_class.expects(:ovconfchg).with('-ns','eaagt',
        '-set','SpaceUtilWarningThreshold','80,/=90,/mnt/c=60,/tmp=100,/unknown=80',
        '-set','SpaceUtilMinorThreshold','85,/mnt/a=50,/mnt/b=80,/tmp=100,/unknown=85',
        '-set','SpaceUtilMajorThreshold','90,/mnt/a=10,/mnt/b=85,/mnt/c=92,/tmp=100,/unknown=90',
        '-set','SpaceUtilCriticalThreshold','95,/mnt/b=90,/mnt/c=99,/mnt/x=90,/tmp=100,/unknown=95'
      )
      run_in_catalog(@mnt_a)
    end

    it "should change an existing entry II" do
      described_class.expects(:ovconfchg).with('-ns','eaagt',
        '-set','SpaceUtilWarningThreshold','80,/=90,/mnt/a=40,/mnt/b=60,/mnt/c=60,/tmp=100,/unknown=80',
        '-set','SpaceUtilMinorThreshold','85,/mnt/a=50,/mnt/b=90,/tmp=100,/unknown=85',
        '-set','SpaceUtilMajorThreshold','90,/mnt/a=60,/mnt/b=85,/mnt/c=92,/tmp=100,/unknown=90',
        '-set','SpaceUtilCriticalThreshold','95,/mnt/b=90,/mnt/c=99,/mnt/x=90,/tmp=100,/unknown=95'
      )
      run_in_catalog(@mnt_b)
    end

    it "should be able to remove an entry" do
      described_class.expects(:ovconfchg).with('-ns','eaagt',
        '-set','SpaceUtilWarningThreshold','80,/=90,/mnt/a=40,/mnt/c=60,/unknown=80',
        '-set','SpaceUtilMinorThreshold','85,/mnt/a=50,/mnt/b=80,/unknown=85',
        '-set','SpaceUtilMajorThreshold','90,/mnt/a=60,/mnt/b=85,/mnt/c=92,/unknown=90',
        '-set','SpaceUtilCriticalThreshold','95,/mnt/b=90,/mnt/c=99,/mnt/x=90,/unknown=95'
      )
      run_in_catalog(@tmp)
    end

    it "should be able to create an entry" do
      described_class.expects(:ovconfchg).with('-ns','eaagt',
        '-set','SpaceUtilWarningThreshold','80,/=90,/mnt/a=40,/mnt/c=60,/mnt/new=10,/tmp=100,/unknown=80',
        '-set','SpaceUtilMinorThreshold','85,/mnt/a=50,/mnt/b=80,/tmp=100,/unknown=85',
        '-set','SpaceUtilMajorThreshold','90,/mnt/a=60,/mnt/b=85,/mnt/c=92,/tmp=100,/unknown=90',
        '-set','SpaceUtilCriticalThreshold','95,/mnt/b=90,/mnt/c=99,/mnt/new=20,/mnt/x=90,/tmp=100,/unknown=95'
      )
      run_in_catalog(@mnt_new)
    end

  end

  describe "when applying multiple resources" do

    it "should perform all necessary changes" do
      # i can only predict the last call which should set all thresholds to the correct values. The calls from the
      # three resources before the last one might come in random order.

      described_class.expects(:ovconfchg).with('-ns','eaagt',
        '-set','SpaceUtilWarningThreshold','80,/=90,/mnt/b=60,/mnt/c=60,/mnt/new=10,/unknown=80',
        '-set','SpaceUtilMinorThreshold','85,/mnt/a=50,/mnt/b=90,/unknown=85',
        '-set','SpaceUtilMajorThreshold','90,/mnt/a=10,/mnt/b=85,/mnt/c=92,/unknown=90',
        '-set','SpaceUtilCriticalThreshold','95,/mnt/b=90,/mnt/c=99,/mnt/new=20,/mnt/x=90,/unknown=95'
      )

      described_class.expects(:ovconfchg).with { |*args| args[0..2] == ['-ns','eaagt','-set'] }.times(3)
      run_in_catalog(@mnt_a,@mnt_b,@tmp,@mnt_new)
    end

  end


end
