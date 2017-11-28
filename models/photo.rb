require 'time' # prevent datamapper typecast deprecation warning

class Photo
  include DataMapper::Resource

  self.per_page = 20

  property :id, Serial
  property :name, String, length: 255
  property :path, String, length: 255
  property :created_at, DateTime, default: lambda { |*| DateTime.now }
  property :deleted_at, DateTime
  property :upa_id, String

  validates_uniqueness_of :name
  validates_presence_of :upa_id, :name, :path

  def destroy
    FileUtils.rm("#{Dir.pwd}/#{self.path}")
  rescue Errno::ENOENT
    # file doesnt exist on disk, do nothing
  ensure
    self.update(deleted_at: Time.now) # soft delete makes for better accountability
  end
end

Photo.auto_upgrade!
