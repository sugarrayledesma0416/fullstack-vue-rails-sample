require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::MixAndMatchAssessmentsController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }

  describe 'GET #show' do
    include RspecJsContentHelpers

    let(:activity) { create_open_ended_assessment(program) }

    def do_request
      get(
        instructor_mix_and_match_assessment_path(
          id: activity.id, program_id: program.id
        )
      )
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'finds the activity with the specified id and renders the show view' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        expect(assigns(:activity)).to eq(activity)
      end
    end
  end

  describe 'GET #index' do
    def create_concept_from_strand(strand, lesson)
      create(
        :concept,
        assessment: strand.assessment?,
        id: strand.location,
        lesson: lesson,
        name: strand.title.singularize
      )
    end

    let(:course) { create(:course, program: program) }
    let(:unit_1) { create(:unit, program: program, rank: 1) }
    let(:unit_2) { create(:unit, program: program, rank: 2) }
    let(:lesson_1) { create(:lesson, name: 'Lesson 1', unit: unit_1) }
    let(:lesson_2) { create(:lesson, name: 'Lesson 2', unit: unit_2) }

    # Create three strands in lesson 1. One is a non-assessment strand,
    # the other two are assessment strands.
    # Also create an assessment strand in lesson 2.
    # Create activities in all the strands. This will allow verifying
    # that only the activities in the assessment strands of the specified
    # lesson appear, and when a strand is also specified, only activities
    # in the specified strand.

    let(:non_assessment_strand) do
      create(:toc_entry, assessment: false, title: 'non-assessment')
    end

    let(:non_assessment_concept) do
      create_concept_from_strand(non_assessment_strand, lesson_1)
    end

    let(:lesson_1_assessment_strand_1) do
      create(:toc_entry, assessment: true, title: 'L1 quizzes')
    end

    let(:lesson_1_assessment_concept_1) do
      create_concept_from_strand(lesson_1_assessment_strand_1, lesson_1)
    end

    let(:lesson_1_assessment_strand_2) do
      create(:toc_entry, assessment: true, title: 'L1 tests')
    end

    let(:lesson_1_assessment_concept_2) do
      create_concept_from_strand(lesson_1_assessment_strand_2, lesson_1)
    end

    let(:lesson_2_assessment_strand) do
      create(:toc_entry, assessment: true, title: 'L2 quizzes')
    end

    let(:lesson_2_assessment_concept) do
      create_concept_from_strand(lesson_2_assessment_strand, lesson_2)
    end

    let(:lesson_1_strand_1_assessment) do
      create(
        :activity,
        activity_type: 'exam',
        concept: lesson_1_assessment_concept_1,
        lesson: lesson_1,
        toc_location: lesson_1_assessment_strand_1.location
      )
    end

    let(:lesson_1_strand_2_assessment) do
      create(
        :activity,
        activity_type: 'exam',
        concept: lesson_1_assessment_concept_2,
        lesson: lesson_1,
        toc_location: lesson_1_assessment_strand_2.location
      )
    end

    before do
      lesson_1.toc_entries = [
        non_assessment_strand,
        lesson_1_assessment_strand_1,
        lesson_1_assessment_strand_2
      ]
      lesson_1.save!

      lesson_2.toc_entries = [lesson_2_assessment_strand]
      lesson_2.save!

      # Trigger the let statements for these. Needs to be done
      # after lesson toc entries are saved, so a let! will not work.
      lesson_1_strand_1_assessment
      lesson_1_strand_2_assessment

      # activity in lesson 1 non-assessment strand
      create(
        :activity,
        concept: non_assessment_concept,
        lesson: lesson_1,
        toc_location: non_assessment_strand.location
      )
      # activity in lesson 2 assessment strand
      create(
        :activity,
        concept: lesson_2_assessment_concept,
        lesson: lesson_2,
        toc_location: lesson_2_assessment_strand.location
      )
    end

    def do_request
      get instructor_mix_and_match_assessments_path(
        lesson_id: lesson_1.id, program_id: program.id
      )
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
        # explicitly set focused course
        put(
          instructor_focus_path(program_id: program.id),
          params: {
            focus: "Course,#{course.id}",
            return_to: ''
          }
        )
      end

      it 'returns a json array of activity ids, titles, and URLs' do
        do_request

        expect(JSON.parse(response.body)).to eq(
          [
            {
              'id' => lesson_1_assessment_concept_1.id,
              'name' => lesson_1_assessment_strand_1.title,
              'concept_name' => lesson_1_assessment_concept_1.name,
              'activities' => [
                {
                  'icons' => [],
                  'id' => lesson_1_strand_1_assessment.id,
                  'title' => lesson_1_strand_1_assessment.title,
                  'url' => instructor_mix_and_match_assessment_path(
                    id: lesson_1_strand_1_assessment.id, program_id: program.id
                  )
                }
              ]
            },
            {
              'id' => lesson_1_assessment_concept_2.id,
              'name' => lesson_1_assessment_strand_2.title,
              'concept_name' => lesson_1_assessment_concept_2.name,
              'activities' => [
                {
                  'icons' => [],
                  'id' => lesson_1_strand_2_assessment.id,
                  'title' => lesson_1_strand_2_assessment.title,
                  'url' => instructor_mix_and_match_assessment_path(
                    id: lesson_1_strand_2_assessment.id, program_id: program.id
                  )
                }
              ]
            }
          ]
        )
      end

      it 'ignores the activity matching the current_assessment_id param when specified' do
        get instructor_mix_and_match_assessments_path(
          current_assessment_id: lesson_1_strand_2_assessment.id,
          lesson_id: lesson_1.id,
          program_id: program.id,
        )
        expect(JSON.parse(response.body)).to eq(
          [
            {
              'id' => lesson_1_assessment_concept_1.id,
              'name' => lesson_1_assessment_strand_1.title,
              'concept_name' => lesson_1_assessment_concept_1.name,
              'activities' => [
                {
                  'icons' => [],
                  'id' => lesson_1_strand_1_assessment.id,
                  'title' => lesson_1_strand_1_assessment.title,
                  'url' => instructor_mix_and_match_assessment_path(
                    id: lesson_1_strand_1_assessment.id, program_id: program.id
                  )
                }
              ]
            }
          ]
        )
      end
    end
  end
end
