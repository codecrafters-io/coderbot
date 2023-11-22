class FriendlyIdGenerator
  def self.generate(seed = nil)
    Faker::Config.random = Random.new(seed) if seed

    adjective = Faker::Adjective.unique.positive
    noun = Faker::Creature::Animal.unique.name
    number = Faker::Number.unique.number(digits: 6).to_s

    Faker::UniqueGenerator.clear

    "#{adjective}-#{noun}-#{number}"
  end
end
