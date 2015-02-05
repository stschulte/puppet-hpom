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
class ovpa::install (
  $minversion           = $ovpa::minversion ,
  $version              = $ovpa::version ,
  $required_rpms        = $ovpa::params::required_rpms ,
  $rpm_gpgkey_file      = $ovpa::params::rpm_gpgkey_file ,
  $rpm_gpgkey_name      = $ovpa::params::rpm_gpgkey_name ,
  $rpm_gpgkey_file_2048 = $ovpa::params::rpm_gpgkey_file_2048 ,
  $rpm_gpgkey_name_2048 = $ovpa::params::rpm_gpgkey_name_2048 ,
  $omdir                = $ovpa::params::omdir ,
  $perfdir              = $ovpa::params::perfdir ,
) {

  include ovpa::params
  #include Puppet stdlib
  include stdlib

  #Chain of Installation Commands
  #Ensure HP Public Key is Installed
  #Require Packages
  #Ensure Service Running
  File['hp_rpmgpg_key'] ->
  Exec['hp_rpmgpg_key_exec'] ->
  File['hp_rpmgpg_key_2048'] ->
  Exec['hp_rpmgpg_key_exec_2048'] ->
  #Resource Collector to Ensure all required RPM's ensured
  Package <| title == $required_rpms |> ->
  Package['HPOvOpsAgt']

  #####START OF SECTION TO HANDLE INSTALLATION/UPDATE OF AGENT
  ###################################################
  ########################################################################
  ####Define Required Packages - Ensure all packages are installed
  package { $required_rpms:
    ensure => $version ,
  }
  #Notify ovcd to restart if not gold and HPOvOpsAgt installed/updated
  package { 'HPOvOpsAgt':
    ensure => $version ,
    notify => Service['ovcd'] ,
  }

  ####Check for/Install HP Public Key
  file { 'hp_rpmgpg_key':
    ensure => file ,
    path   => $rpm_gpgkey_file ,
    source => 'puppet:///modules/ovpa/hpPublicKey.pub' ,
  }
  file { 'hp_rpmgpg_key_2048':
    ensure => file ,
    path   => $rpm_gpgkey_file_2048 ,
    source => 'puppet:///modules/ovpa/hpPublicKey2048.pub' ,
  }

  exec { 'hp_rpmgpg_key_exec':
    command => "rpm --import ${rpm_gpgkey_file}" ,
    path    => '/bin:/usr/bin:/sbin' ,
    user    => 'root' ,
    unless  => "rpm -qi ${rpm_gpgkey_name} >/dev/null 2>&1" ,
  }

  exec { 'hp_rpmgpg_key_exec_2048':
    command => "rpm --import ${rpm_gpgkey_file_2048}" ,
    path    => '/bin:/usr/bin:/sbin' ,
    user    => 'root' ,
    unless  => "rpm -qi ${rpm_gpgkey_name_2048} >/dev/null 2>&1" ,
  }

  ####END OF PUBLIC KEY SECTION

}

