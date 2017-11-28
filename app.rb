ENV["RACK_ENV"] ||= "development"

require 'sinatra'
require 'sinatra/reloader' if %w(development test).include?(ENV["RACK_ENV"])
require 'data_mapper'
require 'fileutils'
require 'rmagick'
require 'json'
require 'will_paginate'
require 'will_paginate/data_mapper'
require File.expand_path("boot/#{ENV["RACK_ENV"]}", File.dirname(__FILE__))
Dir[File.expand_path("lib/**/*", File.dirname(__FILE__))].each { |f| require f }

post "/photos" do
  content_type :json

  photo, name = Magick::Image.from_blob(params[:photo]).first, params[:name]

  unless %w(JPEG PNG).include?(photo.format)
    status 422
    return {error: "unsupported image type"}.to_json
  end

  if photo.rows > 5000 || photo.columns > 5000
    status 422
    return {error: "maximum supported image size is 5000x5000"}.to_json
  end

  if photo.rows < 350 || photo.columns < 350
    status 422
    return {error: "minimum supported image size is 350x350"}.to_json
  end

  # organize photos by date to prevent the folder's file descriptor from getting to large with time
  time  = Time.now
  path  = "public/#{time.year}/#{time.month}/#{time.day}"

  FileUtils.mkdir_p(path)

  photo_record = Photo.create(path: "#{path}/#{name}", name: name, upa_id: params[:upa_id])

  if photo_record.errors.any?
    status 422
    return photo_record.errors.to_hash.to_json
  end

  photo.write("#{path}/#{name}")

  {status: "image uploaded successfully"}
end

get "/photos" do
  content_type :json

  photos = Photo.paginate(page: params[:page], per_page: params[:per_page])
  response.headers['Link'] = Paginate.new(request: request, collection: photos, per_page: params[:per_page], page: params[:page]).link_header
  {photos: photos.map(&:attributes)}.to_json
end

get "/photos/:id" do
  content_type :json
  {photo: Photo.get(params[:id]).attributes}.to_json
end

get "/*" do
  content = File.open(params["splat"].first, 'rb').read
  photo = Magick::Image.from_blob(content).first
  content_type photo.mime_type
  body content
end
