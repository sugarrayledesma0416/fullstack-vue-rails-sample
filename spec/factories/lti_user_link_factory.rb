FactoryBot.define do
  factory(:lti_user_link, class: Lti::UserLink) do
    guid { SecureRandom.uuid }
    lti_platform
    platform_user_id { SecureRandom.uuid }
    user
    platform_user_email do |proxy|
      FFaker::Internet.email("#{proxy.user.first_name} #{proxy.user.last_name}")
    end
  end

  factory(:lti_rostering_user_link, parent: :lti_user_link) do
    lti_platform do |user_link|
      user_link.association(
        :lti_rostering_platform
      )
    end
    user do |user_link|
      user_link.association(
        :lti_rostering_user,
        username: "lti_user_#{user_link.platform_user_id}"
      )
    end
  end
end
