FactoryBot.define do
  factory :dashboard_announcement do
    title { 'Announcement' }
    body { 'Here is the body' }
    supersite { false }
    vol { false }
    link_text { 'Link text' }
    external_url { 'http://reallink.com' }
  end
end
