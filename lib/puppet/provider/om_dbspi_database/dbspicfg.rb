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
    token = nil
    scanner.skip(/(\s+|\n+|#.*?\n)+/)
    if scanner.scan(/"(.*?)"/) or scanner.scan(/(\S+)/)
      token = scanner[1]
    end
    scanner.skip(/(\s+|\n+|#.*?\n)+/)
    token
  end

  def self.instances
    self.initvars
    current_record = nil
    current_settings = {}
    scanner = StringScanner.new(dbspicfg('-e'))
    until scanner.eos?
      case token = parse_next_token(scanner)
      when 'SYNTAX_VERSION'
        @globalconfig['SYNTAX_VERSION'] = parse_next_token(scanner)
        current_record = nil
      when 'ORACLE'
        current_settings['DBTYPE'] = :oracle
        @records[current_record[:name]] = current_record if current_record
        current_record = nil
      when 'HOME'
        current_settings['HOME'] = parse_next_token(scanner)
        @records[current_record[:name]] = current_record if current_record
        current_record = nil
      when 'DATABASE'
        @records[current_record[:name]] = current_record if current_record
        current_settings['DATABASE'] = parse_next_token(scanner)
        current_record = {
          :ensure => :present,
          :name   => current_settings['DATABASE'],
          :home   => current_settings['HOME'],
          :type   => current_settings['DBTYPE'],
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
    new_config = Tempfile.new('dbspi')
    if record[:ensure] == :absent
      @records.delete(record[:name])
    else
      @records[record[:name]] = record
    end
    begin
      # Header defines the syntax version. I'm only aware of version 4 so that is the default
      new_config.write "SYNTAX_VERSION #{@globalconfig['SYNTAX_VERSION'] || 4}\n\n"
      current_dbtype = nil
      current_home = nil
      @records.values.sort_by { |r| [r[:type], r[:home], r[:name]] }.each do |record|
        unless record[:type] and record[:home]
          warning "Database #{record[:name]} has no home or type specified. Skipping database."
          next
        end
        if current_dbtype != record[:type]
          unless current_dbtype.nil?
            new_config.write "\n" # Add extra space if we just changed the db type
          end
          current_dbtype = record[:type]
          new_config.write "#{record[:type].to_s.upcase}\n\n"
        end
        if current_home != record[:home]
          current_home = record[:home]
          new_config.write "  HOME \"#{record[:home]}\"\n"
        end
        if record[:connect]
          new_config.write "    DATABASE \"#{record[:name]}\" CONNECT \"#{record[:connect]}\"\n"
        else
          new_config.write "    DATABASE \"#{record[:name]}\"\n"
        end
        if record[:logfile]
          new_config.write "      LOGFILE \"#{record[:logfile]}\"\n"
        end
        record[:filter].sort.each do |k,v|
          new_config.write "      FILTER #{k} \"#{v}\"\n"
        end
      end
      if listener = @globalconfig['LISTENER']
        if connect_string = @globalconfig['LISTENER_CONNECT']
          new_config.write "  LISTENER \"#{listener}\" CONNECT \"#{connect_string}\"\n"
        else
          new_config.write "  LISTENER \"#{listener}\"\n"
        end
      end
      new_config.close
      execute([command(:dbspicfg), '-i'], :stdinfile => new_config.path)
    ensure
      new_config.close # doesnt matter if file is already closed
      new_config.unlink
    end
  end

  def flush
    @property_hash[:name] ||= resource[:name]
    @property_hash[:filter] ||= {}
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
