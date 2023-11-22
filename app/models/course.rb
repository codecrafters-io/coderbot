class Course
  include ActiveModel::Model
  include ActiveModel::Serialization

  include IsVirtualStoreModel

  attr_accessor :id
  attr_accessor :name
  attr_accessor :slug
  attr_accessor :description_markdown

  validates_presence_of :id
  validates_presence_of :name
  validates_presence_of :slug
  validates_presence_of :description_markdown

  def self.find_by_slug!(slug)
    all.detect { |course| course.slug == slug } || raise(ActiveRecord::RecordNotFound)
  end

  def stages
    CourseStage.all.select { |stage| stage.course_id == id }
  end

  def attributes
    {
      "id" => nil,
      "slug" => nil,
      "description_markdown" => nil,
      "name" => nil
    }
  end
end
