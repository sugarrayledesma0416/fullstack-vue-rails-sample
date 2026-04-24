describe ActivityLinkPresenter do
  include ActivitiesHelper
  include ApplicationHelper
  include ActionView::TestCase::Behavior
  include Capybara::RSpecMatchers

  let(:program) { build_stubbed(:program) }
  let(:instructor) { build_stubbed(:instructor) }
  let(:course) { build_stubbed(:course) }
  let(:toc_presenter) {
    double(InstructorTocPresenter, current_user: instructor,
                                   library_view: 'vhl',
                                   activity_in_course_library?: false,
                                   program: program,
                                   course: course,
                                   has_note?: false,
                                   activity_assignments: [])
  }

  before do
    allow(view).to receive(:spr?).and_return(false)
  end

  context 'for an activity' do
    let(:activity) { build_stubbed(:activity) }
    let(:presenter) { described_class.new(view) }

    describe '#instructor_toc_link' do
      it 'has a popup activity link' do
        expected_link_id = "activity_#{activity.id}"
        expected_url = "/sections/0/activities/#{activity.id}?popup=1"
        expected_body = activity.title.html_safe
        result = Capybara.string(presenter.instructor_toc_link(activity, toc_presenter, true))
        expect(result).to have_link(expected_link_id, :href => expected_url, :text => expected_body)
      end

      context 'for an activity with an activity icon' do
        it 'shows the icon' do
          allow(activity).to receive(:icon).and_return('icon')
          allow(presenter).to receive(:format_activity_icon).with('icon', true).and_return('icon.svg')
          result = Capybara.string(presenter.instructor_toc_link(activity, toc_presenter, true))
          expect(result).to have_selector('span.icon', text: 'icon.svg')
        end
      end

      context 'for an instructor graded activity' do
        it 'has an instructor grading icon' do
          allow(activity).to receive(:instructor_graded?).and_return(true)
          result = Capybara.string(presenter.instructor_toc_link(activity, toc_presenter, true))
          expect(result).to have_selector(
            'button#instructor_graded[title=Instructor-graded] svg'
         )
        end
      end

      context 'for an activity with instructor notes' do
        it 'has an instructor note icon' do
          allow(toc_presenter).to receive(:has_note?).and_return(true)
          result = Capybara.string(presenter.instructor_toc_link(activity, toc_presenter, true))

          expect(result).to have_selector('button#instructor_note svg > title')
          expect(result).to have_content('Instructor Note')
        end
      end

      context 'for a non-instructor graded activity' do
        before do
          allow(activity).to receive(:instructor_graded?).and_return(false)
        end

        it 'does not have an instructor grading button' do
          result = Capybara.string(presenter.instructor_toc_link(activity, toc_presenter, true))
          expect(result).not_to have_selector('button#instructor_graded')
        end

        it 'does not have an instructor grading icon' do
          result = Capybara.string(presenter.instructor_toc_link(activity, toc_presenter, true))
          expect(result).not_to have_selector('button#instructor_graded > svg')
        end
      end
    end
  end

  describe ActivityLinkPresenter::GearMenu do
    include ActionView::TestCase::Behavior

    describe '#render' do
      let(:lesson) { build_stubbed(:lesson) }
      let(:program) { build_stubbed(:program) }
      let(:activity) { build_stubbed(:activity, :instructor_revision_id => 1, :lesson => lesson, :toc_location => 2343) }
      let(:gear_menu) { described_class.new(view, activity, toc_presenter) }

      before do
        allow(activity).to receive(:program).and_return(program)
        allow(activity).to receive(:is_owner?)
        allow(toc_presenter).to receive(:can_edit_course_library?)
        allow(toc_presenter).to receive(:can_edit_activity?)
        allow(toc_presenter).to receive(:can_remove_activity?)
        allow(toc_presenter).to receive(:assignments).and_return([])
      end

      context 'when no link_type is passed' do
        it 'displays a gear link' do
          result = Capybara.string(gear_menu.render)
          expect(result).to have_selector('a', :text => 'Gear')
        end
      end

      context "'when link_type is not 'menu'" do
        it 'displays a single link' do
          result = Capybara.string(gear_menu.render(:link))
          expect(result).not_to have_selector('div.toc_gear')
          expect(result).to have_selector("input#activity_assignment_#{activity.id}[type='hidden'][value='false']")
        end

        context 'when instructor is allowed to edit course library' do
          context 'when the activity is an assessment created by VHL' do
            it 'displays a "copy" link' do
              allow(toc_presenter).to receive(:can_edit_course_library?).and_return(true)
              allow(activity).to receive(:assessment?).and_return(true)
              allow(activity).to receive(:instructor_created?).and_return(false)
              allow(activity).to receive(:exam?).and_return(true)
              result = Capybara.string(gear_menu.render(:link))
              expect(result).to have_selector('.test-icon-copy')
            end
          end
        end

        context 'when instructor is not allowed to edit course library' do
          it 'does not display a remove link' do
            allow(toc_presenter).to receive(:can_edit_course_library?).and_return(false)
            result = Capybara.string(gear_menu.render(:link))
            expect(result).not_to have_selector('.test-icon-remove')
          end
        end

        context 'when instructor is the owner of the activity' do
          let(:gear_menu) { described_class.new(view, activity, toc_presenter) }

          before do
            allow(activity).to receive(:is_owner?).and_return(true)
            allow(toc_presenter).to receive(:can_edit_course_library?).and_return(true)
            allow(toc_presenter).to receive(:can_edit_activity?).and_return(true)
          end

          it 'displays an edit link' do
            result = Capybara.string(gear_menu.render(:link))
            expect(result).to have_selector('.test-icon-edit')
          end

          context 'when the course the instructor is focused on is closed' do
            it 'does not display an edit link' do
              allow(course).to receive(:open?).and_return(false)
              allow(toc_presenter).to receive(:can_edit_activity?).and_return(false)
              result = Capybara.string(gear_menu.render(:link))
              expect(result).not_to have_selector('.test-icon-edit')
            end
          end

          context 'when the activity is a shared igc' do
            before do
              allow(activity).to receive(:is_shared_copy?).and_return(true)
            end

            it 'does not display an edit link' do
              result = Capybara.string(gear_menu.render(:link))
              expect(result).not_to have_selector('.test-icon-edit')
            end

            it 'does not display a copy link' do
              result = Capybara.string(gear_menu.render(:link))
              expect(result).not_to have_selector('.test-icon-copy')
            end

            it 'does not display a remove link' do
              result = Capybara.string(gear_menu.render(:link))
              expect(result).not_to have_selector('.test-icon-remove')
            end
          end
        end

        context 'when instructor is not the owner of the activity' do
          it 'does not display an edit link' do
            allow(activity).to receive(:is_owner?).and_return(false)
            allow(toc_presenter).to receive(:can_edit_activity?).and_return(false)
            result = Capybara.string(gear_menu.render(:link))
            expect(result).not_to have_selector('.test-icon-edit')
          end
        end

        context 'when an institution admin is editing a template' do
          let(:in_institution_admin) { true }
          let(:gear_menu) do
            described_class.new(view, activity, toc_presenter, in_institution_admin)
          end

          context 'when institution admin is adding assessments to a template' do
            it 'does not display the copy icon' do
              allow(toc_presenter).to receive(:can_edit_course_library?).and_return(true)
              allow(activity).to receive(:assessment?).and_return(true)
              allow(activity).to receive(:instructor_created?).and_return(false)
              allow(activity).to receive(:exam?).and_return(true)
              result = Capybara.string(gear_menu.render(:link))
              expect(result).not_to have_selector('.test-icon-copy')
            end
          end

          context 'when institution admin is adding assignments to a template' do
            it 'does not display an edit link' do
              allow(toc_presenter).to receive(:can_edit_course_library?).and_return(true)
              allow(toc_presenter).to receive(:can_edit_activity?).and_return(true)
              result = Capybara.string(gear_menu.render(:link))
              expect(result).not_to have_selector('.test-icon-edit')
            end

            it 'does not display a remove link' do
              allow(toc_presenter).to receive(:can_edit_course_library?).and_return(true)
              result = Capybara.string(gear_menu.render(:link))
              expect(result).not_to have_selector('.test-icon-remove')
            end
          end
        end
      end
    end

    describe 'rubric-related behaviour' do
      RSpec.shared_examples 'a link that allows copying' do
        it 'has no js-class flagging it has having already been copied' do
          expected_js_class = "js-copy-created-activity"
          result = Capybara.string(gear_menu.render(:link))
          expect(result).not_to have_selector(expected_js_class)
        end

        it 'has a label saying that it can be copied' do
          expected_rubric_link = "copy_rubric_link_#{activity.id}"
          result = Capybara.string(gear_menu.render(:link))
          expect(result).to have_link(expected_rubric_link)
        end
      end

      before do
        allow(Maestro::LicenseGroup).to receive(:all).and_return(
          [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
        )
      end

      let(:activity) { create(:activity) }
      let(:gear_menu) do
        described_class.new(view, activity, toc_presenter)
      end

      before do
        allow(activity).to receive(:is_shared_copy?).and_return(false)
      end

      context 'when the activity is instructor-created' do
        before do
          allow(activity).to receive(:instructor_created?).and_return(true)
        end

        it 'returns a gear menu' do
          allow(toc_presenter).to receive(:can_edit_activity?).and_return(true)
          allow(toc_presenter).to receive(:can_edit_course_library?).and_return(true)
          result = Capybara.string(gear_menu.render)
          expect(result).to have_selector('a', :text => 'Gear')
        end
      end

      context 'when the activity is not instructor-created' do
        before do
          allow(activity).to receive(:instructor_created?).and_return(false)
        end

        it 'returns an empty string' do
          expect(gear_menu.render).to eq('')
        end
      end

      context 'when the activity is an assessment' do
        before do
          allow(activity).to receive(:assessment?).and_return(true)
        end

        it 'returns a link to copy the assessment if the activity is an exam' do
          allow(activity).to receive(:exam?).and_return(true)
          allow(toc_presenter).to receive(:can_edit_course_library?).and_return(true)

          expected_link_id = "copy_assessment_link_#{activity.id}"
          result = Capybara.string(gear_menu.render(:link))
          expect(result).to have_link(expected_link_id)
        end

        it 'returns an empty string if the activity is not an exam' do
          allow(activity).to receive(:exam?).and_return(false)
          expect(gear_menu.render).to eq('')
        end
      end

      context 'when the activity has a rubric' do
        before do
          allow(activity).to receive(:has_rubric?).and_return(true)
        end

        context 'when instructor is not allowed to edit course library' do
          before do
            allow(toc_presenter).to receive(:can_edit_course_library?).and_return(false)
          end

          it 'returns an empty string' do
            expect(gear_menu.render).to eq('')
          end
        end

        context 'when instructor is allowed to edit course library,' do
          before do
            allow(toc_presenter).to receive(:can_edit_course_library?).and_return(true)
            allow(toc_presenter).to receive(:can_edit_activity?).and_return(true)
          end

          let(:gear_menu) do
            described_class.new(view, activity, toc_presenter, in_institution_admin)
          end

          context 'when the in_institution_admin argument is true,' do
            let(:in_institution_admin) { true }

            it 'returns an empty string' do
              expect(gear_menu.render).to eq('')
            end
          end

          context 'when the in_institution_admin argument is not true,' do
            let(:in_institution_admin) { false }
            let(:source_activity) { create(:activity) }
            let(:strand) { create(:toc_entry) }
            let(:concept) { create(:concept, id: strand.location.to_i, lesson: lesson) }
            let(:lesson) { create(:lesson, toc_entries: [strand]) }

            let(:activity) do
              create(
                :instructor_created_activity,
                concept:,
                lesson:,
                toc_location: strand.location
              )
            end

            context 'when there is a custom rubric matching the current ' \
                    'activity, course and user,' do
              before do
                CustomRubric.create!(
                  activity_id: activity.id,
                  source_activity_id: source_activity.id,
                  course_id: course.id,
                  instructor_id: instructor.id
                )
              end

              it 'has an edit icon' do
                expected_edit_link = "edit_activity_link_#{activity.id}"
                result = Capybara.string(gear_menu.render(:link))
                expect(result).to have_link(expected_edit_link)
              end

              it 'has not a copy icon' do
                expected_copy_link = "copy_activity_link_#{activity.id}"
                result = Capybara.string(gear_menu.render(:link))
                expect(result).not_to have_link(expected_copy_link)
              end
            end

            context 'when there is a custom rubric record for the current ' \
                    'activity and course, but a different user' do
              before do
                other_user = create(:instructor)
                CustomRubric.create!(
                  activity_id: activity.id,
                  source_activity_id: source_activity.id,
                  course_id: course.id,
                  instructor_id: other_user.id
                )
              end

              include_examples 'a link that allows copying'
            end

            context 'when there is a custom rubric record for the current ' \
                    'activity and user, but a different course' do
              before do
                other_course = create(:course)
                CustomRubric.create!(
                  activity_id: activity.id,
                  source_activity_id: source_activity.id,
                  course_id: other_course.id,
                  instructor_id: instructor.id
                )
              end

              include_examples 'a link that allows copying'
            end

            context 'when there is a custom rubric record for the current ' \
                    'course and user, but a different activity' do
              before do
                other_activity = create(
                  :instructor_created_activity,
                  concept:,
                  lesson:,
                  toc_location: strand.location
                )
                CustomRubric.create!(
                  activity_id: other_activity.id,
                  source_activity_id: source_activity.id,
                  course_id: course.id,
                  instructor_id: instructor.id
                )
              end

              include_examples 'a link that allows copying'
            end
          end
        end
      end
    end
  end
end
