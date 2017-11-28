DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/test.db")

Dir[File.expand_path('../models/*.rb', File.dirname(__FILE__))].each {|file| require file }

DataMapper.finalize
