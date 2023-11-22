class Store
  include Singleton

  CACHE_PATH = "tmp/store.json"

  def self.model_classes
    [
      Course,
      CourseStage
    ]
  end

  def self.ensure_loaded!
    if File.exist?(CACHE_PATH)
      instance.load_from_file(CACHE_PATH)
    else
      instance.fetch_all
      instance.persist(CACHE_PATH)
    end
  end

  def initialize
    @models_map = self.class.model_classes.map { |model_class| [model_class, {}] }.to_h
  end

  def add(model)
    @models_map[model.class][model.id] = model
  end

  def clear
    @models_map = self.class.model_classes.map { |model_class| [model_class, {}] }.to_h
  end

  def load_from_file(path)
    data = JSON.parse(File.read(path))

    data.each do |model_class, serialized_models|
      model_class = Object.const_get(model_class)

      serialized_models.each do |serialized_model|
        instance = model_class.new(serialized_model).tap(&:validate!)
        add(instance)
      end
    end
  end

  def fetch_all
    response = HTTParty.get("https://backend.codecrafters.io/api/v1/courses?include=stages")
    parsed_response = JSON.parse(response.body)

    courses = parsed_response["data"].map do |course_data|
      next if course_data["attributes"]["release-status"] == "alpha"

      Course.new(
        id: course_data["id"],
        slug: course_data["attributes"]["slug"],
        description_markdown: course_data["attributes"]["description-markdown"],
        name: course_data["attributes"]["name"]
      ).tap(&:validate!)
    end.compact

    courses.each do |course|
      add(course)
    end

    course_stages = parsed_response["included"].map do |stage_data|
      CourseStage.new(
        course_id: stage_data["relationships"]["course"]["data"]["id"],
        description_markdown_template: stage_data["attributes"]["description-markdown-template"],
        id: stage_data["id"],
        position: stage_data["attributes"]["position"],
        slug: stage_data["attributes"]["slug"],
        name: stage_data["attributes"]["name"]
      ).tap(&:validate!)
    end

    course_stages.each do |course_stage|
      add(course_stage)
    end
  end

  def models_for(model_class)
    @models_map[model_class].values
  end

  def persist(path)
    FileUtils.mkdir_p(File.dirname(path)) unless Dir.exist?(File.dirname(path))
    File.write(path, JSON.pretty_generate(@models_map.transform_values { |models| models.values.map(&:serializable_hash) }))
  end
end
