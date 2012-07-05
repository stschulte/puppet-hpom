#!/usr/bin/env rspec

require 'spec_helper'

describe Puppet::Type.type(:om_config) do

  before :each do
    #@provider_class = described_class.provide(:fake) { mk_resource_methods }
    #@provider_class.stubs(:suitable?).returns true
    #described_class.stubs(:defaultprovider).returns @provider_class
  end

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:value, :ensure].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for ensure" do
      it "should support present" do
        expect { described_class.new(:name => 'bbc.cb/SSL_REQUIRED', :ensure => :present) }.to_not raise_error
      end

      it "should support absent" do
        expect { described_class.new(:name => 'bbc.cb/SSL_REQUIRED', :ensure => :absent) }.to_not raise_error
      end

      it "should not support other values" do
        expect { described_class.new(:name => 'bbc.cb/SSL_REQUIRED', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe "name" do
      it "should allow simple names" do
        expect { described_class.new(:name => 'agtrep/ACTION_TIMEOUT', :ensure => :present) }.to_not raise_error
      end
      it "should allow names with dots" do
        expect { described_class.new(:name => 'coda.comm/SERVER_PORT', :ensure => :present) }.to_not raise_error
      end
      it "should allow names with underscore" do
        expect { described_class.new(:name => 'conf.core/MERGED_POLICY_LIST_FILENAME', :ensure => :present) }.to_not raise_error
      end
      it "should allow names with leading underscore" do
        expect { described_class.new(:name => 'conf.cluster.RGState.VCS/_OFFLINE_', :ensure => :present) }.to_not raise_error
      end
      it "should allow names with multiple dots" do
        expect { described_class.new(:name => 'sec.core.auth.mapping.secondary/eaagt.actr', :ensure => :present) }.to_not raise_error
      end
      it "should not allow names with no slash" do
        expect { described_class.new(:name => 'OPC_NODENAME', :ensure => :present) }.to raise_error(Puppet::Error, /Name must be.*not OPC_NODENAME/)
      end
      it "should not allow names with spaces" do
        expect { described_class.new(:name => 'eaagt/OPC NODENAME', :ensure => :present) }.to raise_error(Puppet::Error, /Name must be.*not eaagt\/OPC NODENAME/)
      end
    end

    describe "value" do
      it "should allow words" do
        expect { described_class.new(:name => 'eaagt/OPC_NODENAME', :value => 'foo.example.com', :ensure => :present) }.to_not raise_error
      end
      it "should allow numbers" do
        expect { described_class.new(:name => 'agtrep/ACTION_TIMEOUT', :value => '3', :ensure => :present) }.to_not raise_error
      end
      it "should allow spaces" do
        expect { described_class.new(:name => 'eaagt/OPC_INSTALLATION_TIME', :value => 'Mon Nov  8 14:51:51 EST 2010', :ensure => :present) }.to_not raise_error
      end
      it "should allow a list" do
        expect { described_class.new(:name => 'conf.server/NOMULTIPLEPOLICIES', :value => 'mgrconf,msgforwarding,servermsi,ras', :ensure => :present) }.to_not raise_error
      end
    end

  end

end
