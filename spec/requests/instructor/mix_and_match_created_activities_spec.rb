require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::MixAndMatchCreatedActivitiesController do
  let(:content_object) do
    instance_double(
      MaestroActivityEngine::ActivityContent::CompositionContent,
      activity_type: 'composition',
      content_summary: { question_1: 1 },
      grading_method: 'instructor_graded',
      max_attempts: 2,
      points_possible: 10,
      submittable?: true,
      randomizable?: true
    )
  end

  describe 'GET #index' do
    let(:strand) { create(:toc_entry) }
    let(:program) { create(:program) }
    let(:unit) { create(:unit, program: program) }
    let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
    let(:instructor) { create(:instructor) }
    let(:non_instructor) { create(:user) }

    let(:instructor_created_activity) do
      create(
        :instructor_created_activity,
        title: 'Title example',
        lesson: lesson,
        toc_entry_id: strand.location
      )
    end

    let(:instructor_created_activity_2) do
      create(
        :instructor_created_activity,
        title: 'Title example 2',
        lesson: lesson,
        toc_entry_id: strand.location
      )
    end

    let(:course) { create(
      :course,
      owner: instructor,
      program: program,
      first_unit: program.units.first,
      last_unit: program.units.last
    ) }

    let(:section) { create(:section, course: course, instructor: instructor) }

    context 'non_instructor' do
      it 'should return the the second activity when the first one is in the payload' do
        create(:concept, lesson: lesson, program: program, id: strand.location)
        allow(Maestro::User).to receive(:accessible_programs).with(non_instructor.guid).and_return([program])
        allow(Maestro::LicenseGroup).to receive(:all).and_return([])
        document = Nokogiri::XML::Document.new
        direction_line = Nokogiri::XML::Node.new('dl', document)
        bold_text = Nokogiri::XML::Node.new('b', document)
        bold_text.content = 'direction line'
        direction_line.add_child(bold_text)

        allow(content_object).to receive(:dl).and_return(direction_line)
        allow(content_object).to receive(:title).and_return('Title example')
        allow_any_instance_of(described_class).to receive(:content_object).and_return(content_object)

        log_in_user(non_instructor)
        put(
          instructor_focus_path(program_id: program.id),
          params: {
            focus: "Course,#{course.id}",
            return_to: ''
          }
        )

        CourseLibraryActivity.create(activity: instructor_created_activity, course: course, hidden: false)
        CourseLibraryActivity.create(activity: instructor_created_activity_2, course: course, hidden: false)

        get(
          instructor_mix_and_match_created_activities_path(
            lesson_id: lesson.id,
            program_id: program.id,
            course_id: course.id,
            created_activity_id: instructor_created_activity.id
          )
        )

        expect(response.status).to eq(302)
        expect(session[:flash]["flashes"]["error"]).to eq("You must have Instructor access to view the requested page.")
      end
    end

    context 'instructor' do
      before do
        create(:concept, lesson: lesson, program: program, id: strand.location)
        allow(Maestro::User).to receive(:accessible_programs).with(instructor.guid).and_return([program])
        allow(Maestro::LicenseGroup).to receive(:all).and_return([])
        document = Nokogiri::XML::Document.new
        direction_line = Nokogiri::XML::Node.new('dl', document)
        bold_text = Nokogiri::XML::Node.new('b', document)
        bold_text.content = 'direction line'
        direction_line.add_child(bold_text)

        allow(content_object).to receive(:dl).and_return(direction_line)
        allow(content_object).to receive(:title).and_return('Title example')
        allow_any_instance_of(described_class).to receive(:content_object).and_return(content_object)

        # explicitly set focused course
        log_in_user_with_access_to_programs(instructor, [program])
        put(
          instructor_focus_path(program_id: program.id),
          params: {
            focus: "Course,#{course.id}",
            return_to: ''
          }
        )

        CourseLibraryActivity.create(activity: instructor_created_activity, course: course, hidden: false)
        CourseLibraryActivity.create(activity: instructor_created_activity_2, course: course, hidden: false)
      end

      it 'should return the the second activity when the first one is in the payload' do
        get(
          instructor_mix_and_match_created_activities_path(
            lesson_id: lesson.id,
            program_id: program.id,
            course_id: course.id,
            created_activity_id: instructor_created_activity.id
          )
        )
        response_json = JSON.parse response.body

        expect(response_json.length).to eq(1)
        expect(response_json.first["activities"].length).to eq(1)
        expect(response_json.first["activities"].first["id"]).to eq(instructor_created_activity_2.id)
      end

      it 'should return the the first activity when the second one is in the payload' do
        get(
          instructor_mix_and_match_created_activities_path(
            lesson_id: lesson.id,
            program_id: program.id,
            course_id: course.id,
            created_activity_id: instructor_created_activity_2.id
          )
        )
        response_json = JSON.parse response.body

        expect(response_json.length).to eq(1)
        expect(response_json.first["activities"].length).to eq(1)
        expect(response_json.first["activities"].first["id"]).to eq(instructor_created_activity.id)
      end

      it 'should return both activities when neither are in the payload' do
        get(
          instructor_mix_and_match_created_activities_path(
            lesson_id: lesson.id,
            program_id: program.id,
            course_id: course.id,
            created_activity_id: nil
          )
        )
        response_json = JSON.parse response.body

        expect(response_json.length).to eq(1)
        expect(response_json.first["activities"].length).to eq(2)
        expect(response_json.first["activities"].collect{ |x| x["id"] }).to include(instructor_created_activity.id)
        expect(response_json.first["activities"].collect{ |x| x["id"] }).to include(instructor_created_activity_2.id)
      end
    end
  end
end
