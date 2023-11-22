class Buildpack
  include ActiveModel::Model
  include ActiveModel::Serialization

  include IsVirtualStoreModel

  attr_accessor :id
  attr_accessor :course_id
  attr_accessor :slug
  attr_accessor :dockerfile_contents

  validates_presence_of :id
  validates_presence_of :course_id
  validates_presence_of :slug
  validates_presence_of :dockerfile_contents

  def course
    Course.find(course_id)
  end

  def attributes
    {
      "id" => nil,
      "course_id" => nil,
      "slug" => nil,
      "dockerfile_contents" => nil
    }
  end
end
