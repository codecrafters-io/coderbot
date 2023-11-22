class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_validation do
    self.id = SecureRandom.uuid if id.blank?
  end

  def friendly_id
    @friendly_id ||= FriendlyIdGenerator.generate(Integer(id.delete("-"), 16))
  end
end
