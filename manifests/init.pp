# == Class: ovpa
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
class ovpa (
  $policy_server        = $ovpa::params::policy_server ,
  $cert_server          = $ovpa::params::cert_server ,
  $policy_server_coreID = $ovpa::params::policy_server_coreID ,
  $minversion           = $ovpa::params::minversion ,
  $version              = $ovpa::params::version ,
) inherits ovpa::params {

  if ($::operatingsystem in [ 'AIX' ]) {
    fail "${::operatingsystem} not supported. Must be one of RedHat/SLES"
  }
  elsif ($::operatingsystem in [ 'SLES' , 'RedHat' ]) {
    include ovpa::install
    include ovpa::activate
    include ovpa::conf
    include ovpa::proc
    Class['ovpa::install'] ->
    Class['ovpa::activate'] ->
    Class['ovpa::conf'] ->
    Class['ovpa::proc']
  }
  else {
    #FAIL DUE TO UNKNOWN OS
    fail "${::operatingsystem} not supported. Must be one of Redhat/SLES"
  }
}
