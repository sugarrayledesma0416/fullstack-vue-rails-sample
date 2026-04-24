describe Lti::ResourceLinkRedirect do
  include Rails.application.routes.url_helpers

  let(:activity) { build_stubbed(:activity) }
  let(:course) { create(:course) }
  let(:program) { build_stubbed(:program) }
  let(:section) { create(:section, course: course) }

  describe '#url' do
    let(:common_params) do
      {
        program_id: program.id,
        section_guid: section.guid
      }
    end
    let(:dashboard_params) { common_params.merge(view: 'dashboard') }
    let(:activity_params) { common_params.merge(activity_id: activity.id) }

    context 'when current user is a student,' do
      let(:user) { build_stubbed(:student) }
      let(:section_id) { section.id }

      it 'returns the path to the student dashboard with no "preview" ' \
         'query arg if the "view" param is set to "dashboard"' do
        redirect = described_class.new(dashboard_params, section_id, user)

        expect(redirect.url).to eq(
          course_section_path(course_id: course.id, section_id: section.id)
        )
      end

      it 'returns the activity show path with the specified section id if ' \
         'there is no "view" param set to "dashboard"' do
        redirect = described_class.new(activity_params, section_id, user)

        expect(redirect.url).to eq(
          section_activity_path(id: activity.id, section_id: section.id)
        )
      end
    end

    context 'when current user is an instructor,' do
      let(:user) { build_stubbed(:instructor) }
      # current_section_id is 0 when user is an instructor
      let(:section_id) { 0 }

      it 'returns the path to the student dashboard with a "preview" query ' \
         'arg set to "true" if the "view" param is set to "dashboard"' do
        redirect = described_class.new(dashboard_params, section_id, user)

        expect(redirect.url).to eq(
          course_section_path(
            course_id: course.id,
            preview: 'true',
            section_id: section.id
          )
        )
      end

      it 'returns the activity show path with the specified section id if ' \
         'there is no "view" param set to "dashboard"' do
        redirect = described_class.new(activity_params, section_id, user)

        expect(redirect.url).to eq(
          section_activity_path(id: activity.id, section_id: section_id)
        )
      end
    end
  end
end
