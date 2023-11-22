module IsVirtualStoreModel
  extend ActiveSupport::Concern

  included do
    def self.all
      Store.ensure_loaded!
      Store.instance.models_for(self)
    end

    def self.find(id)
      all.detect { |model| model.id == id } || raise(ActiveRecord::RecordNotFound)
    end
  end
end
