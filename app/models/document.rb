# A Document
#
# Can either be linked by a URL or attached from Google Docs.
#
# Evidence is associated with a Document Descriptor
class Document
  include DataMapper::Resource

  property :id, Serial
  property :title, String, :length => 256
  property :link, URI, :length => 1024, :unique_index => true

  belongs_to :document_descriptor, :required => false

  property :reviewed, Boolean, :default => false, :required => true
  property :good, Boolean, :default => true, :required => false

  def display_name
    title
  end

  property :created_at, DateTime
  property :updated_at, DateTime

  is_versioned :on => [:updated_at]

  def complete?
    !link.nil? && !link.to_s.blank?
  end
end
