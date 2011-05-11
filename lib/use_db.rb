module UseDb
  # Options (recommended to use one or both):
  #   :prefix - Specify the prefix to append to ::Rails.env when finding the adapter specification in database.yml
  #   :suffix - Just like :prefix, only concatentated to the end
  # OR
  #   :adapter
  #   :host
  #   :username
  #   :password
  #   ... etc ... same as the options in establish_connection

  @@use_dbs = [ActiveRecord::Base]
  @@debug_print = false

  def use_db(options)
    options_dup = options.dup
    conn_spec = get_use_db_conn_spec(options)
    puts "Establishing connecting on behalf of #{self.to_s} to #{conn_spec.inspect}" if UseDb.debug_print
    establish_connection(conn_spec)
    extend ClassMixin
    @@use_dbs << self unless @@use_dbs.include?(self) || self.to_s.starts_with?("TestModel")
  end

  def self.all_use_dbs
    return @@use_dbs
  end

  def self.debug_print
    return @@debug_print
  end

  def self.debug_print=(newval)
    @@debug_print = newval
  end

  module ClassMixin
    def uses_db?
      true
    end
  end

  def get_use_db_conn_spec(options)
    options.symbolize_keys
    puts "get_use_db_conn_spec OPTIONS=#{options.inspect}" if UseDb.debug_print
    suffix = options.delete(:suffix)
    prefix = options.delete(:prefix)
    rails_env = options.delete(:rails_env) || ::Rails.env
    if (options[:adapter])
      return options
    else
      str = "#{prefix}#{rails_env}#{suffix}"
      puts "get_use_db_conn_spec STR=#{str.inspect}" if UseDb.debug_print
      connections = YAML.load(ERB.new(IO.read("#{::Rails.root.to_s}/config/database.yml"), nil, nil, '_use_db_erbout').result)
      puts "get_use_db_conn_spec CONNECTIONS read. need connections[str]! #{connections.inspect}" if UseDb.debug_print
      raise "Cannot find database specification.  Configuration '#{str}' expected in config/database.yml" if (connections[str].nil?)
      return connections[str]
    end
  end
end

ActiveRecord::Base.extend UseDb

require 'use_db_test_setup'
