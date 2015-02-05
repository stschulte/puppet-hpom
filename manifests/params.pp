#Default parameters for the HP Operations Manager Agent
class ovpa::params {

  include stdlib

  $required_rpms = [
    'HPOvBbc' ,
    'HPOvConf' ,
    'HPOvGlanc' ,
    'HPOvSecCo' ,
    'HPOvSecCC' ,
    'HPOvDepl' ,
    'HPOvPacc' ,
    'HPOvPerfMI' ,
    'HPOvPerfAgt' ,
    'HPOvEaAgt' ,
    'HPOvXpl' ,
    'HPOvCtrl' ,
    'HPOvPerlA' ,
    'HPOvAgtLc' ,
  ]

  #Set correct OM Management system for different environments
  ##UPDATE PRIOR TO USE
  $policy_server        = 'yourhost.example.com'
  $cert_server          = 'yourhost.example.com'
  $policy_server_coreID = '2a4a767c-ab52-11e4-ab2d-03b23e748014'

  # Minimum required version of OM Agent
  $minversion = '11.14.014'

  #Compare opcagtversion custom fact against minversion parameter
  #Toggle Package resources between "present" and "latest" settings
  if ( versioncmp($::opcagtversion, $minversion ) == 0) {
    $version = 'latest'
  }
  else {
    $version = 'present'
  }

  #Default parameters for HP GPG Singing Keys, service names, and directories
  $service_name         = 'OVCtrl'
  $rpm_gpgkey_file      = '/etc/pki/rpm-gpg/hpPublicKey.pub'
  $rpm_gpgkey_name      = 'gpg-pubkey-2689b887-42315a9a'
  $rpm_gpgkey_file_2048 = '/etc/pki/rpm-gpg/hpPublicKey2048.pub'
  $rpm_gpgkey_name_2048 = 'gpg-pubkey-5ce2d476-50be41ba'
  $omdir                = '/opt/OV/bin'
  $perfdir              = '/opt/perf/bin'
  $varperfdir           = '/var/opt/perf'
  $om_lbin              = '/opt/OV/lbin'
}
