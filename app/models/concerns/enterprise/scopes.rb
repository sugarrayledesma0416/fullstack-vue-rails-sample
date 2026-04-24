module Enterprise
  module Scopes
    extend ActiveSupport::Concern

    included do
      scope :including_enterprise, -> { unscope(where: :is_enterprise) }
      scope :enterprise, -> { including_enterprise.where(is_enterprise: true) }
      scope :non_enterprise, -> { where(is_enterprise: [false, nil]) }
    end
  end
end
