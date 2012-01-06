require 'strscan'
require 'tempfile'

Puppet::Type.type(:om_dbspi_database).provide(:dbspicfg) do

  desc "Uses the dbspicfg command to export and import the
      current dbspi configuration"

  commands :dbspicfg => '/var/opt/OV/bin/instrumentation/dbspicfg'

  mk_resource_methods

  def self.initvars
    @globalconfig = {}
    @records = {}
  end

  def self.parse_next_token(scanner)
    scanner.skip(/(\s+|\n+|#.*?\n)+/)
    if scanner.scan(/"(.*?)"/) or scanner.scan(/(\S+)/)
      scanner[1]
    end
  end

  def self.instances
    self.initvars
    current_record = nil
    last_setting = {}
    scanner = StringScanner.new(dbspicfg('-e'))
    until scanner.eos?
      case token = parse_next_token(scanner)
      when 'SYNTAX_VERSION'
        @globalconfig['SYNTAXVERSION'] = parse_next_token(scanner)
        current_record = nil
      when 'ORACLE'
        last_setting['DBTYPE'] = :oracle
        @records[current_record[:name]] = current_record if current_record
        current_record = nil
      when 'HOME'
        last_setting['HOME'] = parse_next_token(scanner)
        @records[current_record[:name]] = current_record if current_record
        current_record = nil
      when 'DATABASE'
        @records[current_record[:name]] = current_record if current_record
        last_setting['DATABASE'] = parse_next_token(scanner)
        current_record = {
          :ensure => :present,
          :name   => last_setting['DATABASE'],
          :home   => last_setting['HOME'],
          :type   => last_setting['DBTYPE'],
          :filter => {}
        }
        if @records.include? current_record[:name]
          warning "Found duplicate database entry: #{current_record[:name]}"
        end
      when 'CONNECT'
        connect_string = parse_next_token(scanner)
        if current_record.nil?
          @globalconfig['LISTENER_CONNECT'] = connect_string
        else
          current_record[:connect] = connect_string
        end
      when 'LOGFILE'
        current_record[:logfile] = parse_next_token(scanner) unless current_record.nil?
      when 'FILTER'
        metric = parse_next_token(scanner)
        filter = parse_next_token(scanner)
        unless current_record.nil?
          current_record[:filter][metric.intern] = filter
        end
      when 'LISTENER'
        @records[current_record[:name]] = current_record if current_record
        current_record = nil
        @globalconfig['LISTENER'] = parse_next_token(scanner)
      else
        warning "Found unrecognized token: #{token}"
      end
      scanner.skip(/(\s+|\n+|#.*?\n)+/)
    end
    @records[current_record[:name]] = current_record if current_record

    # convert our hash array into true provider instances
    @records.values.map { |r| new(r) }
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.flush(record)
    tempfile = Tempfile.new('dbspi')
    if record[:ensure] == :absent
      @records.delete(record[:name])
    else
      @records[record[:name]] = record
    end
    begin
      if syntax_version = @globalconfig['SYNTAX_VERSION']
        stdin_file.write "SYNTAX_VERSION #{syntax_version}\n"
        stdin_file.write ""
      end
      current_dbtype = nil
      current_home = nil
      @records.values.sort_by { |r| [r[:type], r[:home], r[:name]] }.each do |record|
        if current_dbtype != record[:type]
          tempfile.write "#{record[:type]}\n"
        end
        if current_home != record[:home]
          tempfile.write "  HOME \"#{record[:home]}\"\n"
        end
        if record[:connect]
          tempfile.write "    DATABASE \"#{record[:name]}\" CONNECT \"#{record[:connect]}\"\n"
        else
          tempfile.write "    DATABASE \"#{record[:name]}\"\n"
        end
        if record[:logfile]
          tempfile.write "      LOGFILE \"#{record[:logfile]}\"\n"
        end
        record[:filter].each do |k,v|
          tempfile.write "      FILTER #{k} \"#{v}\"\n"
        end
      end
      if listener = @globalconfig['LISTENER']
        if connect_string = @globalconfig['LISTENER_CONNECT']
          tempfile.write "  LISTENER \"#{listener}\" CONNECT \"#{connect_string}\"\n"
        else
          tempfile.write "  LISTENER \"#{listener}\"\n"
        end
      end
      tempfile.close
      execute([command(:dbspicfg), '-i'], :stdinfile => tempfile.path)
    ensure
      tempfile.close # doesnt matter if file is already closed
      tempfile.unlink
    end
  end

  def flush
    @property_hash[:name] ||= resource[:name]
    self.class.flush(@property_hash)
  end

  def create
    @resource.class.validproperties.each do |property|
      if value = @resource.should(property)
        @property_hash[property] = value
      end
    end
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    get(:ensure) != :absent
  end

end
