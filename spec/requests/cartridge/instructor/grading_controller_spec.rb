require 'requests/shared_require_instructor_examples'

describe Cartridge::Instructor::GradingController do
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  def create_fill_in_the_blanks_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'fill_in_the_blanks.xml'),
      program,
      grading_method: 'auto'
    )
  end

  let(:school) { create(:school) }
  let(:cartridge_consumer) { create(:cartridge_consumer, school: school) }
  let(:contexts_owner) do
    create(:cartridge_contexts_owner, school: school).user
  end
  let(:instructor) do
    create(:cartridge_instructor_user_link, school: school).user
  end
  let(:program) { create(:program_with_lessons) }
  let(:course) { create(:course) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity_1) { create(:activity, lesson: program.lessons.first) }
  let(:activity_2) { create(:activity, lesson: program.lessons.first) }
  let(:activity_3) { create(:activity, lesson: program.lessons.first) }
  let(:student_1) { create(:cartridge_student, schools: [school]) }
  let(:student_2) { create(:cartridge_student, schools: [school]) }
  let(:credit_category) do
    create(:category, course: course, credit_only: true, max_attempts: Random.rand(1..9),  weighting_percent: 50)
  end

  shared_examples 'require logged in cartridge instructor' do |format|
    include_examples 'require logged in user', format

    it 'redirects to the access problem page when logged-in user is not an ' \
       'instructor' do
      user = create(:user)
      log_in_user_with_access_to_programs(user, [program])

      do_request

      expect(response).to redirect_to(ua_home_path)
      expect(flash[:error]).to eq(
        'You must have Instructor access to view the requested page.'
      )
    end
  end

  before do
    create(
      :cartridge_course_context_detail,
      course: course,
      section: section,
      school: school
    )
    create(:enrollment, section: section, user: student_1)
    create(:enrollment, section: section, user: student_2)
  end

  describe '#show' do
    let(:target_path) do
      cartridge_instructor_section_grading_path(
        section_id: section.id,
        id: activity_1.id
      )
    end

    def do_request
      get(target_path)
    end

    include_examples 'require logged in cartridge instructor'

    context 'with a logged in cartridge instructor,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      context 'when no submitted or completed attempts exist,' do
        it 'redirects to the grading style page' do
          do_request

          expect(response).to redirect_to(
            instructor_grading_styles_path(
              program_id: program.id,
              activity_id: activity_1.id,
              task_type: GradingTask::UNASSIGNED_ACTIVITIES
            )
          )
        end
      end

      context 'when attempts exist for unassigned activities and need grading,' do
        before do
          create(
            :attempt_submitted,
            activity: activity_1,
            user: student_1,
            section: section
          )
          create(
            :attempt_submitted,
            activity: activity_1,
            user: student_2,
            section: section
          )
          create(
            :attempt_submitted,
            activity: activity_2,
            user: student_2,
            section: section
          )
        end

        context 'when no grading set exists for this activity,' do
          it 'creates a grading set and redirects to the grading style page' do
            expect do
              do_request
            end.to change(GradingSet, :count).by(1)

            expect(GradingSet.last).to have_attributes(
              activity_id: activity_1.id,
              program_id: program.id,
              user_id: instructor.id,
              student_id_list: [student_1.id, student_2.id].join(',')
            )
            expect(session[:grading_done_return_to]).to eq(
              cartridge_section_activity_path(section, activity_1)
            )

            expect(response).to redirect_to(
              instructor_grading_styles_path(
                program_id: program.id,
                activity_id: activity_1.id,
                task_type: GradingTask::UNASSIGNED_ACTIVITIES
              )
            )
          end
        end

        context 'when a grading set already exists for this activity,' do
          it 'updates the grading set and redirects to the grading style page' do
            grading_set = create(
              :grading_set,
              activity: activity_1,
              program: program,
              instructor: instructor
            )

            expect do
              do_request
            end.not_to change(GradingSet, :count)

            expect(grading_set.reload).to have_attributes(
              activity_id: activity_1.id,
              program_id: program.id,
              user_id: instructor.id,
              student_id_list: [student_1.id, student_2.id].join(',')
            )
            expect(session[:grading_done_return_to]).to eq(
              cartridge_section_activity_path(section, activity_1)
            )

            expect(response).to redirect_to(
              instructor_grading_styles_path(
                program_id: program.id,
                activity_id: activity_1.id,
                task_type: GradingTask::UNASSIGNED_ACTIVITIES
              )
            )
          end
        end
      end

      context 'when attempts exist for assigned activities and need grading,' do
        before do
          create(
            :assignment,
            assignable: activity_1,
            category: credit_category,
            current: true,
            due_date: 2.days.ago.to_date,
            section: section
          )
          create(
            :assignment,
            assignable: activity_2,
            category: credit_category,
            current: true,
            due_date: 2.days.ago.to_date,
            section: section
          )
          create(
            :attempt_submitted,
            activity: activity_1,
            user: student_1,
            section: section
          )
          create(
            :attempt_submitted,
            activity: activity_1,
            user: student_2,
            section: section
          )
          create(
            :attempt_submitted,
            activity: activity_2,
            user: student_2,
            section: section
          )
        end

        context 'when no grading set exists for this activity,' do
          it 'creates a grading set and redirects to the grading style page' do
            expect do
              do_request
            end.to change(GradingSet, :count).by(1)

            expect(GradingSet.last).to have_attributes(
                                         activity_id: activity_1.id,
                                         program_id: program.id,
                                         user_id: instructor.id,
                                         student_id_list: [student_1.id, student_2.id].join(',')
                                       )
            expect(session[:grading_done_return_to]).to eq(
                                                          cartridge_section_activity_path(section, activity_1)
                                                        )

            expect(response).to redirect_to(
                                  instructor_grading_styles_path(
                                    program_id: program.id,
                                    activity_id: activity_1.id,
                                    task_type: GradingTask::NEEDS_GRADING
                                  )
                                )
          end
        end

        context 'when a grading set already exists for this activity,' do
          it 'updates the grading set and redirects to the grading style page' do
            grading_set = create(
              :grading_set,
              activity: activity_1,
              program: program,
              instructor: instructor
            )

            expect do
              do_request
            end.not_to change(GradingSet, :count)

            expect(grading_set.reload).to have_attributes(
                                            activity_id: activity_1.id,
                                            program_id: program.id,
                                            user_id: instructor.id,
                                            student_id_list: [student_1.id, student_2.id].join(',')
                                          )
            expect(session[:grading_done_return_to]).to eq(
                                                          cartridge_section_activity_path(section, activity_1)
                                                        )

            expect(response).to redirect_to(
                                  instructor_grading_styles_path(
                                    program_id: program.id,
                                    activity_id: activity_1.id,
                                    task_type: GradingTask::NEEDS_GRADING
                                  )
                                )
          end
        end
      end
    end
  end
end
