describe Cartridge::Instructor::CourseSettingsController, type: :controller do
  let(:school) { create(:school) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, program: program, school: school) }
  let(:section) { create(:section, course: course) }
  let!(:assignment) { create(:assignment, section: section) }
  let(:context_id) { SecureRandom.uuid }
  let!(:course_context_detail) do
    create(
      :cartridge_course_context_detail,
           lms_context_id: context_id,
           course: course,
           section: section,
           school: school
    )
  end

  let(:category) do
    create(
      :category,
      course: course,
      weighting_percent: 100,
      max_attempts: Random.rand(1..2)
    )
  end
  let(:activity) { build_stubbed(:activity) }
  let(:new_end_date) { course.end_date + 10.days }
  let(:prior_course_end_date) { course.end_date - 10.days }
  let(:new_max_attempts) { Random.rand(3..5) }
  let(:course_params) do
    {
      allow_audio_transcripts: '1',
      video_subtitle_languages: '1',
      video_transcript_languages: '1',
      end_date: new_end_date.strftime('%m-%d-%Y')
    }
  end
  let(:scoring_ruleset_params) do
    {
      ignore_accents: '0',
      ignore_capitalization: '0',
      ignore_punctuation: '0'
    }
  end
  let(:course_settings_params) do
    course_params.merge(
      category: {
        category.id => {
          max_attempts: new_max_attempts,
          scoring_ruleset: scoring_ruleset_params
        }
      }
    )
  end

  describe '#update' do
    def do_request
      put :update, params: {
        section_id: section.id,
        course: course_settings_params,
        activity_id: activity.id,
        task_type: 'needs_grading_section'
      }
    end

    before do
      fake_login(instructor)
    end

    it 'redirects to the grading styles page' do
      do_request
      expect(response).to redirect_to(
        instructor_grading_styles_path(course.program_id, activity.id, task_type: 'needs_grading_section')
      )
    end

    context 'when the course validation fails' do
      let(:course_params) do
        {
          allow_audio_transcripts: '1',
          video_subtitle_languages: '1',
          video_transcript_languages: '1',
          end_date: 'invalid date'
        }
      end

      it 'sends an error message' do
        do_request
        expect(flash[:errors]).to start_with('End date is required.')
      end

      it 'does not update the course' do
        expect do
          do_request
        end.not_to change { course.reload.attributes }
      end

      it 'does not update the category' do
        expect do
          do_request
        end.not_to change { category.reload.attributes }
      end
    end

    context 'when the category validation fails' do
      let(:new_max_attempts) { 'invalid value' }

      it 'sends an error message' do
        do_request
        expect(flash[:errors]).to start_with(
          'Maximum Attempts Allowed must be a number'
        )
      end

      it 'does not update the course' do
        expect do
          do_request
        end.not_to change { course.reload.attributes }
      end

      it 'does not update the category' do
        expect do
          do_request
        end.not_to change { category.reload.attributes }
      end
    end

    context 'when successful' do
      it 'updates the course' do
        do_request

        expect(course.reload).to have_attributes(
          course_params.merge(
            end_date: new_end_date,
            allow_audio_transcripts: true,
            video_subtitle_languages: '1',
            video_transcript_languages: '1'
          )
        )
      end

      it 'updates the category' do
        do_request

        expect(category.reload).to have_attributes(
          max_attempts: new_max_attempts
        )
      end

      it 'updates the scoring ruleset associated with the category' do
        expect(category.reload.current_scoring_ruleset).to have_attributes(
          ignore_accents: false,
          ignore_capitalization: false,
          ignore_punctuation: false
        )
      end

      it 'sends a success message' do
        do_request
        expect(flash[:notice]).to eq 'The course settings have been updated.'
      end

      context 'with the new course end date greater than the current one' do
        it 'updates the assignments due date' do
          do_request
          expect(assignment.reload.due_date).to eq new_end_date
        end

        it 'updates the course end date' do
          do_request
          expect(course.reload.end_date).to eq new_end_date
        end
      end

      context 'with the new course end date less than the current one' do
        before do
          course_params[:end_date] = prior_course_end_date.strftime('%m-%d-%Y')
        end

        it 'updates the assignments due date' do
          do_request
          expect(assignment.reload.due_date).to eq prior_course_end_date
        end

        it 'updates the course end date' do
          do_request
          expect(course.reload.end_date).to eq prior_course_end_date
        end
      end

      context 'with the new course end date less than the most recent assignment due date' do
        let(:prior_last_assignment_due_date) { (assignment.due_date - 1.day) }

        before do
          course_params[:end_date] = prior_last_assignment_due_date.strftime('%m-%d-%Y')
        end

        it 'updates the assignments due date' do
          do_request
          expect(assignment.reload.due_date).to eq prior_last_assignment_due_date
        end

        it 'updates the course end date' do
          do_request
          expect(course.reload.end_date).to eq prior_last_assignment_due_date
        end
      end
    end

    context 'when there is more than one course associated with the course context details' do
      let(:program2) { create(:program) }
      let(:course2) { create(:course_with_section, program: program2, school: school) }
      let(:section2) { create(:section, course: course2) }
      let!(:assignment2) { create(:assignment, section: section2) }
      let!(:category2) do
        create(
          :category,
          course: course2,
          weighting_percent: 100,
          max_attempts: Random.rand(1..2)
        )
      end
      let!(:course_context_detail2) do
        create(
          :cartridge_course_context_detail,
          lms_context_id: context_id,
          course: course2,
          section: section2,
          school: school
        )
      end

      context 'when successful' do
        it 'updates all the courses' do
          do_request

          expect(course.reload).to have_attributes(
            course_params.merge(
              end_date: new_end_date,
              allow_audio_transcripts: true,
              video_subtitle_languages: '1',
              video_transcript_languages: '1'
            )
          )

          expect(course2.reload).to have_attributes(
            course_params.merge(
              end_date: new_end_date,
              allow_audio_transcripts: true,
              video_subtitle_languages: '1',
              video_transcript_languages: '1'
            )
          )
        end

        it 'updates the category' do
          do_request

          expect(category.reload).to have_attributes(
                                       max_attempts: new_max_attempts
                                     )
        end

        it 'updates the scoring ruleset associated with the category' do
          expect(category.reload.current_scoring_ruleset).to have_attributes(
                                                               ignore_accents: false,
                                                               ignore_capitalization: false,
                                                               ignore_punctuation: false
                                                             )
        end

        it 'sends a success message' do
          do_request
          expect(flash[:notice]).to eq 'The course settings have been updated.'
        end

        context 'with the new course end date greater than the current one' do
          it 'updates the assignments due date' do
            do_request
            expect(assignment.reload.due_date).to eq new_end_date
          end

          it 'updates the course end date' do
            do_request
            expect(course.reload.end_date).to eq new_end_date
          end
        end

        context 'with the new course end date less than the current one' do
          before do
            course_params[:end_date] = prior_course_end_date.strftime('%m-%d-%Y')
          end

          it 'updates the assignments due date' do
            do_request
            expect(assignment.reload.due_date).to eq prior_course_end_date
          end

          it 'updates the course end date' do
            do_request
            expect(course.reload.end_date).to eq prior_course_end_date
          end
        end

        context 'with the new course end date less than the most recent assignment due date' do
          let(:prior_last_assignment_due_date) { (assignment.due_date - 1.day) }

          before do
            course_params[:end_date] = prior_last_assignment_due_date.strftime('%m-%d-%Y')
          end

          it 'updates the assignments due date' do
            do_request
            expect(assignment.reload.due_date).to eq prior_last_assignment_due_date
          end

          it 'updates the course end date' do
            do_request
            expect(course.reload.end_date).to eq prior_last_assignment_due_date
          end
        end
      end
    end

    context 'when there is more than one CourseContextDetail with the same context id but in different schools' do
      let(:school2) { create(:school) }
      let(:program2) { create(:program) }
      let(:course2) { create(:course_with_section, program: program2, school: school2) }
      let(:section2) { create(:section, course: course2) }
      let!(:assignment2) { create(:assignment, section: section2) }
      let!(:category2) do
        create(
          :category,
          course: course2,
          weighting_percent: 100,
          max_attempts: Random.rand(1..2)
        )
      end
      let!(:course_context_detail2) do
        create(
          :cartridge_course_context_detail,
          lms_context_id: context_id,
          course: course2,
          section: section2,
          school: school2
        )
      end

        it 'only updates the correct course' do
          do_request

          expect(course.reload).to have_attributes(
                                     course_params.merge(
                                       end_date: new_end_date,
                                       allow_audio_transcripts: true,
                                       video_subtitle_languages: '1',
                                       video_transcript_languages: '1'
                                     )
                                   )

          expect(course2.reload).to_not have_attributes(
                                      course_params.merge(
                                        end_date: new_end_date,
                                        allow_audio_transcripts: true,
                                        video_subtitle_languages: '1',
                                        video_transcript_languages: '1'
                                      )
                                    )
        end
    end
  end
end
