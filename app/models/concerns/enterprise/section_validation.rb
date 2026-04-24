module Enterprise
  module SectionValidation
    extend ActiveSupport::Concern

    included do
      validate :section_cannot_be_enterprise
    end

    private def section_cannot_be_enterprise
      if section&.is_enterprise?
        errors.add(:section, 'cannot be an enterprise section')
      end
    end
  end
end
