# == Class: ovpa::proc
#
# Managed configuration for HP Operations Manager Monitoring & Performance Reporting agent
#
# === Parameters
#
# === Variables
#
# === Authors
#
# Jeremy Grant <Jeremy.Grant@outlook.com>
#
class ovpa::proc (
  $omdir        = $ovpa::params::omdir,
  $perfdir      = $ovpa::params::perfdir,
  $om_lbin      = $ovpa::params::om_lbin,
  $service_name = $ovpa::params::service_name,
) {

  include ovpa::params

  #System D not supported
  Service {
    provider => init ,
  }
  #####START OF SECTION TO HANDLE RUNNING PROCESSES FOR OM AGENT
  ###################################################
  ########################################################################
  service { $service_name:
    ensure => running ,
  }

  service { 'ovcd':
    ensure     => running ,
    pattern    => "${omdir}/ovcd",
    hasrestart => false,
    hasstatus  => false,
    restart    => "${omdir}/ovc -restart",
    start      => "${omdir}/ovc -start",
    stop       => "${omdir}/ovc -kill",
    subscribe  => Package['HPOvOpsAgt'],
  }
  service { 'ovconfd':
    ensure     => running ,
    pattern    => "${om_lbin}/conf/ovconfd",
    hasrestart => false,
    hasstatus  => false,
    restart    => "${omdir}/ovc -restart ovconfd",
    start      => "${omdir}/ovc -start ovconfd",
    stop       => "${omdir}/ovc -stop ovconfd",
  }
  service { 'opcacta':
    ensure     => running ,
    pattern    => "${om_lbin}/eaagt/opcacta",
    hasrestart => false,
    hasstatus  => false,
    restart    => "${omdir}/ovc -restart opcacta",
    start      => "${omdir}/ovc -start opcacta",
    stop       => "${omdir}/ovc -stop opcacta",
  }
  service { 'opcmsga':
    ensure     => running ,
    pattern    => "${om_lbin}/eaagt/opcmsga",
    hasrestart => false,
    hasstatus  => false,
    restart    => "${omdir}/ovc -restart opcmsga",
    start      => "${omdir}/ovc -start opcmsga",
    stop       => "${omdir}/ovc -stop opcmsga",
  }
  service { 'ovbbccb':
    ensure     => running ,
    pattern    => "${omdir}/ovbbccb",
    hasrestart => false,
    hasstatus  => false,
    restart    => "${omdir}/ovc -restart ovbbccb",
    start      => "${omdir}/ovc -start ovbbccb",
    stop       => "${omdir}/ovc -stop ovbbccb",
  }
####END OF SECTION TO HANDLE RUNNING PROCESSES FOR OM AGENT
###################################################
########################################################################


#####START OF SECTION TO HANDLE RUNNING PROCESSES FOR PERF AGENT
###################################################
########################################################################
  service { 'scope':
    ensure     => running ,
    pattern    => "${perfdir}/scopeux",
    hasrestart => false,
    hasstatus  => false,
    start      => "${perfdir}/ovpa start scope",
  }
  service { 'alarm':
    ensure     => running ,
    name       =>  perfalarm,
    pattern    => "${perfdir}/perfalarm",
    hasrestart => false,
    hasstatus  => false,
    start      => "${perfdir}/ovpa start alarm",
  }
  service { 'coda':
    ensure     => running ,
    pattern    => "${om_lbin}/perf/coda",
    hasrestart => false,
    hasstatus  => false,
    start      => "${omdir}/ovc -start coda",
  }
#####END OF SECTION TO HANDLE RUNNING PROCESSES PERF AGENT
###################################################
########################################################################

}
