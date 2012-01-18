#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:om_dbspi_database).provider(:dbspicfg) do

  before :each do
    described_class.stubs(:suitable?).returns true
    described_class.stubs(:command).with(:dbspicfg).returns '/var/opt/OV/bin/instrumentation/dbspicfg'
    Puppet::Type.type(:om_dbspi_database).stubs(:defaultprovider).returns described_class
  end

  after :each do
    described_class.initvars
  end

  it "should support prefetching" do
    described_class.should respond_to :prefetch
  end

  it "should support instances" do
    described_class.should respond_to :instances
  end

  [:connect,:logfile,:filter,:home].each do |property|
    it "should have getter and setter for property #{property}" do
      described_class.new.should respond_to property
      described_class.new.should respond_to "#{property}=".intern
    end
  end

  describe "when running instances" do

    it "should parse a single database entry" do
      described_class.stubs(:dbspicfg).with('-e').returns File.read(my_fixture('simple'))
      described_class.expects(:warning).never
      instances = described_class.instances.sort_by {|p| p.get(:name)}
      instances[0].get(:name).should == 'OMLE'
      instances[0].get(:connect).should == 'itouser/secret@host:1521/OMLE'
      instances[0].get(:logfile).should == '/u01/app/oracle/diag/rdbms/omle/OMLE/trace/alert_OMLE.log'
      instances[0].get(:home).should == '/u01/app/oracle/product/11.2.0/dbhome_1'
      instances[0].get(:type).should == :oracle
      instances[0].get(:filter).should == {}
    end

    it "should parse multiple databases" do
      described_class.stubs(:dbspicfg).with('-e').returns File.read(my_fixture('filter'))
      described_class.expects(:warning).never
      instances = described_class.instances.sort_by {|p| p.get(:name)}

      instances[0].get(:name).should == 'OMLE'
      instances[0].get(:connect).should == 'itouser/secret@host:1521/OMLE'
      instances[0].get(:logfile).should == '/u01/app/oracle/diag/rdbms/omle/OMLE/trace/alert_OMLE.log'
      instances[0].get(:home).should == '/u01/app/oracle/product/11.2.0/dbhome_1'
      instances[0].get(:type).should == :oracle
      instances[0].get(:filter).should == {
        :'16' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')",
        :'206' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')"
      }

      instances[1].get(:name).should == 'OMLP'
      instances[1].get(:connect).should == 'itouser/secret@host:1521/OMLP'
      instances[1].get(:logfile).should == '/u01/app/oracle/diag/rdbms/omlp/OMLP/trace/alert_OMLP.log'
      instances[1].get(:home).should == '/u01/app/oracle/product/11.2.0/dbhome_1'
      instances[1].get(:type).should == :oracle
      instances[1].get(:filter).should == {
        :'16' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')",
        :'206' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')"
      }
    end

    it "should parse input with weired style" do
      described_class.stubs(:dbspicfg).with('-e').returns File.read(my_fixture('mixlines'))
      described_class.expects(:warning).never
      instances = described_class.instances.sort_by {|p| p.get(:name)}

      instances[0].get(:name).should == 'OMLE'
      instances[0].get(:connect).should == 'itouser/secret@host:1521/OMLE'
      instances[0].get(:logfile).should == '/u01/app/oracle/diag/rdbms/omle/OMLE/trace/alert_OMLE.log'
      instances[0].get(:home).should == '/u01/app/oracle/product/11.2.0/dbhome_1'
      instances[0].get(:type).should == :oracle
      instances[0].get(:filter).should == {
        :'16' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')",
        :'206' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')"
      }

      instances[1].get(:name).should == 'OMLP'
      instances[1].get(:connect).should == 'itouser/secret@host:1521/OMLP'
      instances[1].get(:logfile).should == '/u01/app/oracle/diag/rdbms/omlp/OMLP/trace/alert_OMLP.log'
      instances[1].get(:home).should == '/u01/app/oracle/product/11.2.0/dbhome_1'
      instances[1].get(:type).should == :oracle
      instances[1].get(:filter).should == {
        :'16' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')",
        :'206' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')"
      }
    end

    it "should parse input with multiple homes and databases" do
      described_class.stubs(:dbspicfg).with('-e').returns File.read(my_fixture('multihomes'))
      described_class.expects(:warning).never
      instances = described_class.instances.sort_by {|p| p.get(:name)}

      instances.size.should == 3


      instances[0].get(:name).should == 'FOO'
      instances[0].get(:connect).should == 'itouser/secret@host:1521/FOO'
      instances[0].get(:logfile).should == '/u01/app/oracle/diag/rdbms/foo/FOO/trace/alert_FOO.log'
      instances[0].get(:home).should == '/u01/app/oracle/product/11.2.0/dbhome_2'
      instances[0].get(:type).should == :oracle
      instances[0].get(:filter).should == {
        :'200' => "y not in z",
        :'201' => "foo in bar"
      }


      instances[1].get(:name).should == 'OMLE'
      instances[1].get(:connect).should == 'itouser/secret@host:1521/OMLE'
      instances[1].get(:logfile).should == '/u01/app/oracle/diag/rdbms/omle/OMLE/trace/alert_OMLE.log'
      instances[1].get(:home).should == '/u01/app/oracle/product/11.2.0/dbhome_1'
      instances[1].get(:type).should == :oracle
      instances[1].get(:filter).should == {
        :'16' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')",
        :'206' => "tablespace_name not in (select tablespace_name from dba_tablespaces where contents = 'UNDO')"
      }


      instances[2].get(:name).should == 'OMLP'
      instances[2].get(:connect).should == 'itouser/secret@host:1521/OMLP'
      instances[2].get(:logfile).should == '/u01/app/oracle/diag/rdbms/omlp/OMLP/trace/alert_OMLP.log'
      instances[2].get(:home).should == '/u01/app/oracle/product/11.2.0/dbhome_1'
      instances[2].get(:type).should == :oracle
      instances[2].get(:filter).should == {
        :'118' => "x not in y"
      }
    end

    it "should warn about duplicate database entries" do
      described_class.stubs(:dbspicfg).with('-e').returns File.read(my_fixture('duplicate'))
      described_class.expects(:warning).with('Found duplicate database entry: OMLE')
      described_class.instances
    end

    it "should warn about invalid tokens" do
      described_class.stubs(:dbspicfg).with('-e').returns File.read(my_fixture('invalidtoken'))
      described_class.expects(:warning).with('Found unrecognized token: ORACLCE')
      described_class.expects(:warning).with('Found unrecognized token: LOGGFILE')
      described_class.expects(:warning).with('Found unrecognized token: /u01/app/oracle/diag/rdbms/omle/OMLE/trace/alert_OMLE.log')
      described_class.instances
    end

  end

end
