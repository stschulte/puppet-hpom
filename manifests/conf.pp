# == Class: ovpa:conf
#
# Managed configuration for HP Operations Manager
# Monitoring & Performance Reporting agent
#
# === Parameters
#
# === Variables
#
# === Examples
#
# === Authors
#
# Jeremy Grant <Jeremy.Grant@outlook.com>
#
class ovpa::conf (
  $omdir   = $ovpa::params::omdir ,
  $perfdir = $ovpa::params::perfdir ,
) {

  include ovpa::params

  #####START OF SECTION TO HANDLE CONFIGURATION/ACTIVATION OF AGENT
  ###################################################

  $hostname = $::fqdn

  #Check if opc_nodename custom fact matches the FQDN of server
  #if not, reset agent config with FQDN of system
  if (( $::opc_nodename != $hostname ) and ($::opc_nodename != undef )) {
    $change_node = 'yes'
  }
  else {
    $change_node = 'no'
  }
  #Check if opc_ip_address custom fact matches the primary public interface IP address of server
  #if not, reset agent config with primary public IP
  if (( versioncmp($::opc_ip_address, $::ipaddress) != 0) and ($::opc_ip_address != undef )) {
    $change_ip = 'yes'
  }
  else {
    $change_ip = 'no'
  }
  #Check if opc_server_bind custom fact matches primary public interface IP address of server
  #if not, reset agent config with primary public IP
  if (( versioncmp($::opc_server_bind, $::ipaddress ) != 0 ) and ($::opc_server_bind != undef )) {
    $change_srv_bind = 'yes'
  }
  else {
    $change_srv_bind = 'no'
  }

  #Check if opc_client_bind custom fact matches primary public interface IP address of server
  #if not, reset agent config with primary public IP
  if (( versioncmp($::opc_client_bind, $::ipaddress ) != 0) and ($::opc_client_bind != undef )) {
    $change_client_bind = 'yes'
  }
  else {
    $change_client_bind = 'no'
  }


  #Check to see if "change" variables were toggled on
  #perform necessary restart or generate new coreid/certreq
  if (( $change_node == 'yes') and  ( $change_ip == 'no' )) {
    Exec['Stop_Agent']->
    Exec['Configure_Nodename']->
    Exec['Configure_NameSrv_Localname']->
    Exec['Configure_Client_Bind']->
    Exec['Configure_Server_Bind']->
    Exec['Config_Refresh']->
    Exec['Restart_Agent']
  }
  elsif (( $change_node == 'no') and ( $change_ip == 'yes' )) {
    Exec['Stop_Agent']->
    Exec['Configure_IP']->
    Exec['Configure_Client_Bind']->
    Exec['Configure_Server_Bind']->
    Exec['Config_Refresh']->
    Exec['Restart_Agent']
  }
  elsif (( $change_node == 'yes') and ( $change_ip == 'yes' )) {
    Exec['Stop_Agent']->
    Exec['Configure_Nodename']->
    Exec['Configure_NameSrv_Localname']->
    Exec['Configure_IP']->
    Exec['Configure_Client_Bind']->
    Exec['Configure_Server_Bind']->
    Exec['Config_Refresh']->
    Exec['Restart_Agent']
  }

  #Stop OM Agent for config change/refresh
  if ($change_ip == 'yes') or ($change_node == 'yes') {
    exec { 'Stop_Agent':
      command => "${omdir}/ovc -kill",
      path    => $omdir,
      timeout => '600',
      before  => Exec['Config_Refresh'] ,
    }
    #Re-Read OM Agent Configuration
    exec { 'Config_Refresh':
      command => "${omdir}/ovconfchg",
      path    => $omdir,
      before  => Exec['Restart_Agent'],
      require => Exec['Stop_Agent'],
    }
    #Restart OM Agent
    exec { 'Restart_Agent':
      command => "${omdir}/opcagt -cleanstart",
      path    => $omdir,
      require => Exec['Stop_Agent'],
      timeout => '600' ,
    }
  }
  #Configure Agent configured hostname according to system fact
  exec { 'Configure_Nodename':
    command => "${omdir}/ovconfchg -ns eaagt -set OPC_NODENAME ${hostname}" ,
    path    => "/usr/bin:${omdir}",
    unless  => "/usr/bin/test '${::opc_nodename}' = '${hostname}'",
  }
  exec { 'Configure_NameSrv_Localname':
    command => "${omdir}/ovconfchg -ns eaagt -set OPC_NAMESRV_LOCAL_NAME ${hostname}" ,
    path    => "/usr/bin:${omdir}",
    unless  => "/usr/bin/test '${::opc_nodename}' = '${hostname}'",
  }

  #Configure Agent configured IP address according to system fact
  exec { 'Configure_IP':
    command => "${omdir}/ovconfchg -ns eaagt -set OPC_IP_ADDRESS ${::ipaddress}",
    path    => "/usr/bin:${omdir}",
    unless  => "/usr/bin/test '${::opc_ip_address}' = '${::ipaddress}'",
  }
  #Configure Agent Server Bind IP Address according to system fact
  exec { 'Configure_Client_Bind':
    command => "${omdir}/ovconfchg -ns bbc.cb -set SERVER_BIND_ADDR ${::ipaddress};${omdir}/ovconfchg",
    path    => "/usr/bin:${omdir}",
    unless  => "/usr/bin/test '${::opc_server_bind}' = '${::ipaddress}'",
  }
  #Configure Agent Client Bind IP Address according to system fact
  exec { 'Configure_Server_Bind':
    command => "${omdir}/ovconfchg -ns bbc.http -set CLIENT_BIND_ADDR ${::ipaddress};${omdir}/ovconfchg",
    path    => "/usr/bin:${omdir}",
    unless  => "/usr/bin/test '${::opc_client_bind}' = '${::ipaddress}'",
  }

#####END OF SECTION TO HANDLE CONFIGURATION/ACTIVATION OF AGENT
###################################################
########################################################################
}
