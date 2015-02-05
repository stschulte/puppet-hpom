# == Class: ovpa:activate
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
class ovpa::activate (
  $policy_server        = $ovpa::policy_server ,
  $cert_server          = $ovpa::cert_server ,
  $policy_server_coreID = $ovpa::policy_server_coreID ,
  $omdir                = $ovpa::params::omdir ,
  $perfdir              = $ovpa::params::perfdir ,
) {

  include ovpa::params
  #include Puppet stdlib
  include stdlib

  Exec['Configure_OML'] ->
  Exec['Activate_OML'] ->
  Exec['Set_Sec_Auth_Manager'] ->
  Exec['Set_Sec_Auth_Manager_ID'] ->
  Exec['Set_Cert_Manager'] ->
  Exec['License_OM'] ->
  Exec['License_Glance']

  #####START OF SECTION TO HANDLE INSTALLATION/UPDATE OF AGENT
  ###################################################
  ########################################################################
  ####Define Required Packages - Ensure all packages are installed
  #####START OF SECTION TO HANDLE CONFIGURATION/ACTIVATION OF AGENT
  ###################################################
  ########################################################################
  exec { 'Configure_OML':
    command => "${omdir}/OpC/install/oainstall.sh -configure -agent",
    creates => [
    '/var/opt/OV/installation/inventory/HPOvAgtLc.xml',
    '/var/opt/OV/installation/inventory/HPOvBbc.xml',
    '/var/opt/OV/installation/inventory/HPOvConf.xml',
    '/var/opt/OV/installation/inventory/HPOvCtrl.xml',
    '/var/opt/OV/installation/inventory/HPOvDepl.xml',
    '/var/opt/OV/installation/inventory/HPOvEaAgt.xml',
    '/var/opt/OV/installation/inventory/HPOvGlanc.xml',
    '/var/opt/OV/installation/inventory/HPOvPacc.xml',
    '/var/opt/OV/installation/inventory/HPOvPerfAgt.xml',
    '/var/opt/OV/installation/inventory/HPOvPerfMI.xml',
    '/var/opt/OV/installation/inventory/HPOvPerlA.xml',
    '/var/opt/OV/installation/inventory/HPOvSecCC.xml',
    '/var/opt/OV/installation/inventory/HPOvSecCo.xml',
    '/var/opt/OV/installation/inventory/HPOvXpl.xml',
    '/var/opt/OV/installation/inventory/Operations-agent.xml',
    ],
    unless  => '/bin/ls -la /var/opt/OV/installation/inventory/Operations-agent.xml',
  }

  #Activate OML Agent
  exec { 'Activate_OML':
    command => "${omdir}/OpC/install/opcactivate -srv ${policy_server} -cert_srv ${cert_server}",
    unless  => "${omdir}/ovconfget sec.core.auth MANAGER | /bin/grep -i '${policy_server}'",
  }

  #Ensure Proper Sec Manager Setting:
  exec { 'Set_Sec_Auth_Manager':
    command => "${omdir}/ovconfchg -ns sec.core.auth -set MANAGER ${policy_server}" ,
    unless  => "${omdir}/ovconfget sec.core.auth MANAGER | /bin/grep -i '${policy_server}'" ,
  }

  #Ensure Proper Sec Manager Setting:
  exec { 'Set_Sec_Auth_Manager_ID':
    command => "${omdir}/ovconfchg -ns sec.core.auth -set MANAGER_ID ${policy_server_coreID}" ,
    unless  => "${omdir}/ovconfget sec.core.auth MANAGER_ID | /bin/grep -i '${policy_server_coreID}'" ,
  }

  #Ensure Proper Sec Manager Setting:
  exec { 'Set_Cert_Manager':
    command => "${omdir}/ovconfchg -ns sec.cm.client -set CERTIFICATE_SERVER ${cert_server}" ,
    unless  => "${omdir}/ovconfget sec.cm.client CERTIFICATE_SERVER| /bin/grep -i '${cert_server}'" ,
  }

  exec { 'License_OM':
    command => "${omdir}/oalicense -set -type PERMANENT 'HP Operations OS Inst Adv SW LTU'",
    unless  => "${omdir}/oalicense -get 'HP Operations OS Inst Adv SW LTU' | /bin/grep PERMANENT",
  }

  exec { 'License_Glance':
    command => "${omdir}/oalicense -set -type PERMANENT 'Glance Software LTU'",
    unless  => "${omdir}/oalicense -get 'Glance Software LTU' | /bin/grep PERMANENT",
  }

}

