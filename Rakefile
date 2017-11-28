require 'rake'
require 'data_mapper'
require 'fileutils'

task :environment do
  require File.expand_path('boot/development', File.dirname(__FILE__))
end

namespace :db do
  task :migrate, [:version] => :load_migrations do |t, args|
    if vers = args[:version] || ENV['VERSION']
      puts "=> Migrating up to version #{vers}"
      migrate_up!(vers)
    else
      puts "=> Migrating up"
      migrate_up!
    end
    puts "<= #{t.name} done"
  end

  desc "Create the database"
  task :create, [:repository] => :environment do |t, args|
    repo = args[:repository] || ENV['REPOSITORY'] || :default
    config = DataMapper.repository(repo).adapter.options.symbolize_keys
    user, password, host = config[:user], config[:password], config[:host]
    database       = config[:database]  || config[:path].sub(/\//, "")
    charset        = config[:charset]   || ENV['CHARSET']   || 'utf8'
    collation      = config[:collation] || ENV['COLLATION'] || 'utf8_unicode_ci'
    puts "=> Creating database '#{database}'"

    case config[:adapter]
    when 'postgres'
      system("createdb", "-E", charset, "-h", host, "-U", user, database)
    when 'mysql'
      query = [
        "mysql", "--user=#{user}", (password.blank? ? '' : "--password=#{password}"), (%w[127.0.0.1 localhost].include?(host) ? '-e' : "--host=#{host} -e"),
        "CREATE DATABASE #{database} DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}".inspect
      ]
      system(query.compact.join(" "))
    when 'sqlite3'
      DataMapper.setup(DataMapper.repository.name, config)
    else
      raise "Adapter #{config[:adapter]} not supported for creating databases yet."
    end
    puts "<= #{t.name} done"
  end

  desc "List migrations descending, showing which have been applied"
  task :migrations => :load_migrations do
    puts migrations.sort.reverse.map {|m| "#{m.position}  #{m.name}  #{m.needs_up? ? '' : 'APPLIED'}"}
  end

  task :load_migrations => :environment do
    require 'dm-migrations/migration_runner'
    FileList['db/migrate/*.rb'].each do |migration|
      load migration
    end
  end
end
