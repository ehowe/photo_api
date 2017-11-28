class Paginate
  attr_reader :model, :per_page, :page, :request

  def initialize(options={})
    @collection = options[:collection]
    @model      = options[:scope] || @collection.model
    @per_page   = options[:per_page]
    @page       = options[:page] || 1
    @request    = options[:request]
  end

  def link_header
    [self.next, self.prev, self.last].compact.join(", ")
  end

  def next
    return nil if page == total_pages
    "<#{self.request.path_info}&page=#{page + 1}&per_page=#{per_page}>; rel='next'"
  end

  def prev
    return nil if page == 1
    "<#{self.request.path_info}&page=#{page - 1}&per_page=#{per_page}>; rel='prev'"
  end

  def last
    "<#{self.request.path_info}&page=#{total_pages}&per_page=#{per_page}>; rel='last'"
  end

  def total_pages
    (self.model.count.to_f / (self.per_page || self.model.per_page).to_f).ceil
  end
end
