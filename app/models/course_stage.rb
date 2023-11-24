class CourseStage
  include ActiveModel::Model
  include ActiveModel::Serialization

  include IsVirtualStoreModel

  attr_accessor :id
  attr_accessor :course_id
  attr_accessor :slug
  attr_accessor :description_markdown_template
  attr_accessor :position
  attr_accessor :name

  validates_presence_of :id
  validates_presence_of :course_id
  validates_presence_of :slug
  validates_presence_of :description_markdown_template
  validates_presence_of :position
  validates_presence_of :name

  def attributes
    {
      "id" => nil,
      "course_id" => nil,
      "slug" => nil,
      "description_markdown_template" => nil,
      "position" => nil,
      "name" => nil
    }
  end

  def course
    Course.find(course_id)
  end

  def description_markdown_for_language(language)
    variables = {}

    Language.all.each do |l|
      variables["lang_is_#{l.slug}"] = l.eql?(language)
    end

    variables["reader_is_bot"] = true

    Mustache.render(description_markdown_template, variables)
  end

  def previous_stage
    course.stages.sort_by(&:position).take_while { |stage| stage.position < position }.last
  end

  def tester_test_case_json
    {
      slug: slug,
      tester_log_prefix: "stage-#{position}",
      title: "Stage #{position}: #{name}"
    }
  end
end
