require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

require Dir.pwd + "/app.rb"
require 'rack/test'
require 'fileutils'
require 'pry'

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure do |config|
  config.include RSpecMixin

  config.after(:each) do
    FileUtils.rm_rf("public/")
    Photo.destroy!
  end
end
