module UserEmailHelper
  def user_display_email(user)
    if user.lti_rostering?
      user.lti_rostering_user_link.platform_user_email
    elsif user.one_roster?
      user.one_roster_linked_user.email
    else
      user.email
    end
  end
end
