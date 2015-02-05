# opcagtversion/opcprimarymgr/opcsecmgr
# # Find OVPA Agent Version and agent config variables for OPC_PRIMARY_MGR & MANAGER

require 'facter'

#Set OM Directories
om_var_dir   = "/var/opt/OV"
perf_var_dir = "/var/opt/perf"

case Facter.value('operatingsystem')
when /SLES|RedHat/
  omdir   = "/opt/OV/bin"
  perfdir = "/opt/perf/bin"
when /AIX/
  omdir   = "/usr/lpp/OV/bin"
  perfdir = "/usr/lpp/perf/bin"
end

#opcagtversion fact
opcagt_file = "#{omdir}/opcagt"
if FileTest.exists?(opcagt_file)
  #opcagtversion
  ##Find Agent Version
  Facter.add(:opcagtversion) do
    setcode do
      opcagtversion = `#{omdir}/opcagt -version`
      opcagtversion.chomp!
    end
  end
end

#opcprimarymgr,opc_nodename,opc_ip_address,opc_server_bind, opc_client_bind & opcsecmgr facts
ovconf_file = "#{omdir}/ovconfget"
if FileTest.exists?(ovconf_file)
  # opcprimarymgr
  # #Find OPC_PRIMARY_MGR from eaagt config namespace
  Facter.add(:opcprimarymgr) do
    setcode do
      opcprimarymgr = `#{omdir}/ovconfget eaagt OPC_PRIMARY_MGR`
      opcprimarymgr.chomp!
    end
  end

  # opc_nodename
  # #Find OPC_NODENAME from eaagt config namespace
  Facter.add(:opc_nodename) do
    setcode do
      opc_nodename = `#{omdir}/ovconfget eaagt OPC_NODENAME`
      opc_nodename.chomp!
    end
  end

  # opc_ip_address
  # #Find OPC_IP_ADDRESS from eaagt config namespace
  Facter.add(:opc_ip_address) do
    setcode do
      opc_ip_address = `#{omdir}/ovconfget eaagt OPC_IP_ADDRESS`
      opc_ip_address.chomp!
    end
  end

  # opc_server_bind
  # #Find SERVER_BIND_ADDR from bbc.cb config namespace
  Facter.add(:opc_server_bind) do
    setcode do
      opc_server_bind = `#{omdir}/ovconfget bbc.cb SERVER_BIND_ADDR`
      opc_server_bind.chomp!
    end
  end

  # opc_client_bind
  # #Find CLIENT_BIND_ADDR from bbc.http config namespace
  Facter.add(:opc_client_bind) do
    setcode do
      opc_client_bind = `#{omdir}/ovconfget bbc.http CLIENT_BIND_ADDR`
      opc_client_bind.chomp!
    end
  end

  # opcsecmgr
  # # Find Agent Manager from sec.core.auth config namespace
  Facter.add(:opcsecmgr) do
    setcode do
      opcsecmgr = `#{omdir}/ovconfget sec.core.auth MANAGER`
      opcsecmgr.chomp!
    end
  end
end

