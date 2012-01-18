require 'puppet/provider/parsedfile'

dbspiconfig = '/var/opt/OV/dbspi/defaults'

Puppet::Type.type(:om_dbspi_option).provide(:parsed, :parent => Puppet::Provider::ParsedFile, :default_target => dbspiconfig, :filetype => :flat) do

  confine :exists => dbspiconfig

  text_line :comment, :match => /^\s*#/
  text_line :blank, :match => /^\s*$/

  record_line :parsed, :fields => %w{name value}

end
