class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_validation do
    self.id = SecureRandom.uuid if id.blank?
  end
end
