require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe ActivitiesController, new_gb_sync: true do
  let!(:student) { create(:student) }
  let!(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_toc_entries) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit:) }
  let(:strand) { create(:toc_entry) }
  let(:concept) { create(:concept, id: strand.location.to_i, lesson:) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }

  let(:content_filepath) do
    File.join('spec', 'fixtures', 'xml', 'hybrid_reading_with_inline_rubric.xml')
  end
  let!(:source_activity) { create(:activity, concept:, lesson:) }
  let!(:rubric_activity) { create(:activity, concept:, lesson:) }

  let(:instructor_created_activity) do
    build(
      :instructor_created_activity,
      concept:,
      lesson:,
      license_group_id: 1,
      toc_location: strand.location
    )
  end
  let(:course_licenses) { [] }

  before do
    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
    )

    allow(Maestro::LicensedContent).to receive(:find_for_user_and_program).and_return(
      Maestro::LicensedContent.new('license_group_ids' => [1], 'lessons' => '*')
    )
  end

  describe 'GET /rubric' do
    let(:filepath_1) do
      File.join('spec', 'fixtures', 'xml', 'composition_with_rubric.xml')
    end

    let(:filepath_2) do
      File.join('spec', 'fixtures', 'xml', 'solo_video_recording_with_rubric.xml')
    end

    let(:activity) { create(:activity, concept:, lesson:) }
    let(:alternate_revision_id) { activity.cms_revision_id + 1000 }

    def do_request(extra_params = {})
      get(
        rubric_section_activity_path(
          { id: activity.id, section_id: section.id }.merge(extra_params)
        )
      )
    end

    before do
      create(:active_enrollment, section:, user: student)
      log_in_user_with_access_to_programs(student, [program])

      allow(Activity).to receive(:filepath_from_revision_id).with(
        activity.cms_revision_id,
        false,
        false
      ).and_return(filepath_1)

      allow(Activity).to receive(:filepath_from_revision_id).with(
        alternate_revision_id,
        false,
        false
      ).and_return(filepath_2)
    end

    context 'when a cms_revision_id parameter is passed,' do
      it 'assigns the activity content matching the specified cms_revision_id' do
        do_request(cms_revision_id: alternate_revision_id)

        expect(response).to be_ok

        expect(assigns(:activity).content_object.class).to eq(
          MaestroActivityEngine::ActivityContent::SoloVideoRecordingContent
        )
      end
    end

    context 'when no cms_revision_id parameter is passed,' do
      context 'when no attempt exists for the current user,' do
        it 'assigns the content matching the current activity cms_revision_id' do
          do_request

          expect(response).to be_ok

          expect(assigns(:activity).content_object.class).to eq(
            MaestroActivityEngine::ActivityContent::CompositionContent
          )
        end
      end

      context 'when an attempt exists for the current user,' do
        it 'assigns the content matching the cms_revision_id of the attempt,' do
          create(
            :attempt,
            activity:,
            cms_revision_id: alternate_revision_id,
            section:,
            user: student
          )

          do_request

          expect(response).to be_ok

          expect(assigns(:activity).content_object.class).to eq(
            MaestroActivityEngine::ActivityContent::SoloVideoRecordingContent
          )
        end
      end
    end
  end

  describe 'GET /show' do
    def do_request
      get(
        section_activity_path(
          section_id: section.id,
          id: rubric_activity.id
        )
      )
    end

    before do
      allow(Activity).to receive(:filepath_from_revision_id).with(
        anything,
        true,
        false
      ).and_return(content_filepath)

      allow(Activity).to receive(:filepath_from_revision_id).with(
        rubric_activity.cms_revision_id,
        false,
        false
      ).and_return(content_filepath)

      instructor_created_activity.save!

      create(:active_enrollment, section:, user: student)
    end

    it 'loads the rubric from custom_rubric table as student' do
      log_in_user_with_access_to_programs(student, [program])

      rubric_doc = Nokogiri::XML.parse(instructor_created_activity.content).children.first.at('rubric')
      rubric_doc.at('criteria/title').content = 'New First Criteria Title'

      CustomRubric.create!(
        activity_id: instructor_created_activity.id,
        course_id: course.id,
        draft: false,
        instructor_id: instructor.id,
        source_activity_id: source_activity.id,
        source_rubric_id: instructor_created_activity.content_object.inline_rubric&.last.rubric.cms_rubric_id,
        stored_rubric: rubric_doc.to_xml
      )

      do_request
      expect(response.body).to match(/New First Criteria Title/)
    end

    it 'displays the inline_rubric correctly as instructor' do
      course_licenses << Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })
      allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)

      log_in_user_with_access_to_programs(instructor, [program])

      rubric_doc = Nokogiri::XML.parse(instructor_created_activity.content).children.first.at('rubric')
      rubric_doc.at('criteria/title').content = 'Change First Criteria Title'

      CustomRubric.create!(
        activity_id: instructor_created_activity.id,
        course_id: course.id,
        draft: false,
        instructor_id: instructor.id,
        source_activity_id: source_activity.id,
        source_rubric_id: instructor_created_activity.content_object.inline_rubric&.last.rubric.cms_rubric_id,
        stored_rubric: rubric_doc.to_xml
      )

      do_request
      expect(response.body).to match(/Change First Criteria Title/)
    end
  end
end
