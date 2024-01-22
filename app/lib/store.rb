class Store
  include Singleton

  CACHE_PATH = "tmp/store.json"

  def self.ensure_loaded!
    if File.exist?(CACHE_PATH)
      instance.load_from_file(CACHE_PATH)
    else
      instance.fetch_all
      instance.persist(CACHE_PATH)
    end
  end

  def initialize
    @models_map = {}
  end

  def add(model)
    @models_map[model.class] ||= {}
    @models_map[model.class][model.id] = model
  end

  def clear
    @models_map = {}
  end

  def fetch_all
    response = HTTParty.get("https://backend.codecrafters.io/api/v1/courses?include=stages,buildpacks")
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

    models = parsed_response["included"].map do |included_resource|
      case included_resource["type"]
      when "course-stages"
        CourseStage.new(
          course_id: included_resource["relationships"]["course"]["data"]["id"],
          description_markdown_template: included_resource["attributes"]["description-markdown-template"],
          id: included_resource["id"],
          marketing_markdown: included_resource["attributes"]["marketing-markdown"],
          position: included_resource["attributes"]["position"],
          slug: included_resource["attributes"]["slug"],
          name: included_resource["attributes"]["name"]
        ).tap(&:validate!)
      when "buildpacks"
        Buildpack.new(
          course_id: included_resource["relationships"]["course"]["data"]["id"],
          id: included_resource["id"],
          slug: included_resource["attributes"]["slug"],
          dockerfile_contents: included_resource["attributes"]["dockerfile-contents"]
        )
      else
        raise "Unknown resource type #{included_resource["type"]}"
      end
    end

    models.each do |model|
      add(model)
    end
  end

  def load_from_file(path)
    data = JSON.parse(File.read(path))

    data.each do |model_class, serialized_models|
      model_class = Object.const_get(model_class)

      serialized_models.each do |serialized_model|
        instance = begin
          model_class.new(serialized_model).tap(&:validate!)
        rescue ActiveModel::ValidationError => e
          puts "Failed to load #{model_class} with id #{serialized_model["id"]}: #{e.message}"
          puts "Attributes: #{serialized_model}"
          exit 1
        end

        add(instance)
      end
    end
  end

  def models_for(model_class)
    (@models_map[model_class] || {}).values
  end

  def persist(path)
    FileUtils.mkdir_p(File.dirname(path)) unless Dir.exist?(File.dirname(path))
    File.write(path, JSON.pretty_generate(@models_map.transform_values { |models| models.values.map(&:serializable_hash) }))
  end
end
