require "use_db.rb"
require "test_model.rb"

class UseDbTestSetup

  extend UseDb

  # Used in rake tasks, not normal testing
  def self.other_databases
    YAML.load(File.read("#{::Rails.root.to_s}/config/use_db.yml")).values.collect(&:symbolize_keys!)
  end

  def self.prepare_test_db(options)
    dump_db_structure(options)
    purge_db(options)
    clone_db_structure(options)
  end

  def self.dump_db_structure(options)
    options_dup = options.dup
    options_dup[:rails_env] = "development"
    conn_spec = get_use_db_conn_spec(options_dup)
    #establish_connection(conn_spec)

    test_class = setup_test_model(options[:prefix], options[:suffix], "ForDumpStructure")

    puts "Dumping DB structure #{test_class.inspect}..." if UseDb.debug_print

    case conn_spec["adapter"]
      when "mysql", "oci", "oracle"
        test_class.establish_connection(conn_spec)
        File.open("#{::Rails.root.to_s}/db/#{::Rails.env}_structure.sql", "w+") { |f| f << test_class.connection.structure_dump }
=begin      when "postgresql"
        ENV['PGHOST']     = abcs[::Rails.env]["host"] if abcs[::Rails.env]["host"]
        ENV['PGPORT']     = abcs[::Rails.env]["port"].to_s if abcs[::Rails.env]["port"]
        ENV['PGPASSWORD'] = abcs[::Rails.env]["password"].to_s if abcs[::Rails.env]["password"]
        search_path = abcs[::Rails.env]["schema_search_path"]
        search_path = "--schema=#{search_path}" if search_path
        `pg_dump -i -U "#{abcs[::Rails.env]["username"]}" -s -x -O -f db/#{::Rails.env}_structure.sql #{search_path} #{abcs[::Rails.env]["database"]}`
        raise "Error dumping database" if $?.exitstatus == 1
      when "sqlite", "sqlite3"
        dbfile = abcs[::Rails.env]["database"] || abcs[::Rails.env]["dbfile"]
        `#{abcs[::Rails.env]["adapter"]} #{dbfile} .schema > db/#{::Rails.env}_structure.sql`
      when "sqlserver"
        `scptxfr /s #{abcs[::Rails.env]["host"]} /d #{abcs[::Rails.env]["database"]} /I /f db\\#{::Rails.env}_structure.sql /q /A /r`
        `scptxfr /s #{abcs[::Rails.env]["host"]} /d #{abcs[::Rails.env]["database"]} /I /F db\ /q /A /r`
      when "firebird"
        set_firebird_env(abcs[::Rails.env])
        db_string = firebird_db_string(abcs[::Rails.env])
        sh "isql -a #{db_string} > db/#{::Rails.env}_structure.sql"
=end
      else
        raise "Task not supported by '#{conn_spec["adapter"]}'"
    end

    #if test_class.connection.supports_migrations?
    #  File.open("db/#{::Rails.env}_structure.sql", "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
    #end

    test_class.connection.disconnect!
  end

  def self.clone_db_structure(options)
    options_dup = options.dup
    conn_spec = get_use_db_conn_spec(options_dup)
    #establish_connection(conn_spec)

    test_class = setup_test_model(options[:prefix], options[:suffix], "ForClone")

    puts "Cloning DB structure #{test_class.inspect}..." if UseDb.debug_print

    case conn_spec["adapter"]
      when "mysql"
        test_class.connection.execute('SET foreign_key_checks = 0')
        IO.readlines("#{::Rails.root.to_s}/db/#{::Rails.env}_structure.sql").join.split("\n\n").each do |table|
          test_class.connection.execute(table)
        end
      when "oci", "oracle"
        IO.readlines("#{::Rails.root.to_s}/db/#{::Rails.env}_structure.sql").join.split(";\n\n").each do |ddl|
          test_class.connection.execute(ddl)
        end
=begin      when "postgresql"
        ENV['PGHOST']     = abcs["test"]["host"] if abcs["test"]["host"]
        ENV['PGPORT']     = abcs["test"]["port"].to_s if abcs["test"]["port"]
        ENV['PGPASSWORD'] = abcs["test"]["password"].to_s if abcs["test"]["password"]
        `psql -U "#{abcs["test"]["username"]}" -f db/#{::Rails.env}_structure.sql #{abcs["test"]["database"]}`
      when "sqlite", "sqlite3"
        dbfile = abcs["test"]["database"] || abcs["test"]["dbfile"]
        `#{abcs["test"]["adapter"]} #{dbfile} < db/#{::Rails.env}_structure.sql`
      when "sqlserver"
        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{::Rails.env}_structure.sql`
      when "firebird"
        set_firebird_env(abcs["test"])
        db_string = firebird_db_string(abcs["test"])
        sh "isql -i db/#{::Rails.env}_structure.sql #{db_string}"
=end
      else
        raise "Task not supported by '#{conn_spec["adapter"]}'"
    end

    test_class.connection.disconnect!
  end

  def self.purge_db(options)
    options_dup = options.dup
    conn_spec = get_use_db_conn_spec(options_dup)
    #establish_connection(conn_spec)

    test_class = setup_test_model(options[:prefix], options[:suffix], "ForPurge")

    case conn_spec["adapter"]
      when "mysql"
        test_class.connection.recreate_database(conn_spec["database"])
      when "oci", "oracle"
        test_class.connection.structure_drop.split(";\n\n").each do |ddl|
          test_class.connection.execute(ddl)
        end
      when "firebird"
        test_class.connection.recreate_database!
=begin
      when "postgresql"
        ENV['PGHOST']     = abcs["test"]["host"] if abcs["test"]["host"]
        ENV['PGPORT']     = abcs["test"]["port"].to_s if abcs["test"]["port"]
        ENV['PGPASSWORD'] = abcs["test"]["password"].to_s if abcs["test"]["password"]
        enc_option = "-E #{abcs["test"]["encoding"]}" if abcs["test"]["encoding"]

        ActiveRecord::Base.clear_active_connections!
        `dropdb -U "#{abcs["test"]["username"]}" #{abcs["test"]["database"]}`
        `createdb #{enc_option} -U "#{abcs["test"]["username"]}" #{abcs["test"]["database"]}`
      when "sqlite","sqlite3"
        dbfile = abcs["test"]["database"] || abcs["test"]["dbfile"]
        File.delete(dbfile) if File.exist?(dbfile)
      when "sqlserver"
        dropfkscript = "#{abcs["test"]["host"]}.#{abcs["test"]["database"]}.DP1".gsub(/\\/,'-')
        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{dropfkscript}`
        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{::Rails.env}_structure.sql`
=end
      else
        raise "Task not supported by '#{conn_spec["adapter"]}'"
    end

    test_class.connection.disconnect!
  end

  def self.setup_test_model(prefix="", suffix="", model_suffix="", rails_env=::Rails.env)
puts "PREFIX= #{prefix}" if UseDb.debug_print
puts "SUFFIX= #{suffix}" if UseDb.debug_print
puts "MODEL SUFFIX= #{model_suffix}" if UseDb.debug_print
puts "rails_env= #{rails_env}" if UseDb.debug_print
    prefix ||= ""
    suffix ||= ""
    model_name = "TestModel#{prefix.camelize}#{suffix.camelize}#{model_suffix}".gsub("_","").gsub("-","")
puts "model_name = #{model_name}" if UseDb.debug_print
    return eval(model_name) if eval("defined?(#{model_name})")
    create_test_model(model_name, prefix, suffix, rails_env)
    return eval(model_name)
  end
end