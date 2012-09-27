# RelatedModel mixin
#
# Creates some useful scoping functions that allow you to
# create scopes for relationships with very little code. Example usage:
#
# In your model:
# include RelatedModel
#
# scope managed_by, lambda {|object|
#   related_to_source(object, 'manager_of')}
# }
#
module RelatedModel
  def self.included(model)
    model.class_eval do
      has_many :source_relationships, :as => :source, :class_name =>'Relationship'
      has_many :destination_relationships, :as => :destination, :class_name => 'Relationship'
    end
    model.extend(ClassMethods)
  end

  module ClassMethods
    def related_to_source(object, relationship_type_id)
      object_type = object.class.to_s
      object_id = object.id
      joins(:destination_relationships).where(:relationships => {
        :source_id => object_id,
        :source_type => object_type,
        :relationship_type_id => relationship_type_id
      })
    end

    def related_to_destination(relationship_type_id, object)
      object_type = object.class.to_s
      object_id = object.id
      joins(:source_relationships).where(:relationships => {
        :destination_id => object_id,
        :destination_type => object_type,
        :relationship_type_id => relationship_type_id
      })
    end
  end
end