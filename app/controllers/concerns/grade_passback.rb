module GradePassback
  extend ActiveSupport::Concern

  def process_grade_passback(user, attempt)
    grade_passback(user, attempt)
  end

  def cartridge_grade_params
    session[:cartridge]&.symbolize_keys&.slice(
      :lti_version,
      :consumer_guid,
      :platform_guid
    ) || {}
  end

  private def grade_passback(user, attempt)
    # TODO: Add Google Classroom grade passback here
    if user.cartridge?
      cartridge_grade_passback(user, attempt).process
    end
  end

  private def cartridge_grade_passback(user, attempt)
    Cartridge::GradePassback.new(
      user,
      attempt,
      cartridge_grade_params
    )
  end
end
