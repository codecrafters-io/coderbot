class Language
  attr_reader :slug
  attr_reader :name

  def initialize(slug:, name:)
    @slug = slug
    @name = name
  end

  def self.all
    @all ||= [
      Language.new(slug: "c", name: "C"),
      Language.new(slug: "cpp", name: "C++"),
      Language.new(slug: "clojure", name: "Clojure"),
      Language.new(slug: "crystal", name: "Crystal"),
      Language.new(slug: "csharp", name: "C#"),
      Language.new(slug: "elixir", name: "Elixir"),
      Language.new(slug: "go", name: "Go"),
      Language.new(slug: "haskell", name: "Haskell"),
      Language.new(slug: "java", name: "Java"),
      Language.new(slug: "javascript", name: "JavaScript"),
      Language.new(slug: "kotlin", name: "Kotlin"),
      Language.new(slug: "nim", name: "Nim"),
      Language.new(slug: "php", name: "PHP"),
      Language.new(slug: "python", name: "Python"),
      Language.new(slug: "ruby", name: "Ruby"),
      Language.new(slug: "rust", name: "Rust"),
      Language.new(slug: "swift", name: "Swift")
    ]
  end

  def self.find_by_slug!(slug)
    all.detect(-> { raise "Language with slug #{slug} not found" }) { |language| language.slug.eql?(slug) }
  end

  def self.find_by_language_pack!(language_pack)
    return find_by_slug!("javascript") if language_pack.start_with?("nodejs")
    return find_by_slug!("csharp") if language_pack.start_with?("dotnet")
    find_by_slug!(language_pack.split("-").first)
  end

  def code_file_extension
    {
      "c" => "c",
      "clojure" => "clj",
      "cpp" => "cpp",
      "crystal" => "cr",
      "csharp" => "cs",
      "elixir" => "ex",
      "go" => "go",
      "haskell" => "hs",
      "java" => "java",
      "javascript" => "js",
      "kotlin" => "kt",
      "nim" => "nim",
      "php" => "php",
      "python" => "py",
      "ruby" => "rb",
      "rust" => "rs",
      "swift" => "swift"
    }.fetch(@slug)
  end

  def language_pack
    if @slug.eql?("javascript")
      "nodejs"
    elsif @slug.eql?("csharp")
      "dotnet"
    else
      @slug
    end
  end

  def syntax_highlighting_identifier
    @slug
  end
end
