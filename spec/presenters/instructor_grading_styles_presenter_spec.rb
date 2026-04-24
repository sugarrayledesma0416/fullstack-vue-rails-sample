describe InstructorGradingStylesPresenter do
  before do
    @program = build_stubbed(:program)
    @activity = build_stubbed(:activity)
    @instructor = build_stubbed(:instructor)
    section = build_stubbed(:section)
    @focus = double(Focus, section:, sections: [section])

    allow(Activity).to receive(:find_by_id).and_return(@activity)

    # some tests will modify @focus before the presenter is instantiated
    @opts = lambda do
      {
        program: @program,
        instructor: @instructor,
        focus: @focus,
        activity_id: @activity.id.to_s,
        task_type: 'quux'
      }
    end
  end

  describe '#program' do
    before { @presenter = InstructorGradingStylesPresenter.new(@opts.call) }

    it 'returns the program' do
      expect(@presenter.program).to eql @program
    end
  end

  describe '#activity' do
    before { @presenter = InstructorGradingStylesPresenter.new(@opts.call) }

    it 'returns the activity' do
      expect(@presenter.activity).to eql @activity
    end
  end

  describe '#grading_style' do
    let(:grading_set) { double(GradingSet).as_null_object }

    context 'when grading is not complete' do
      before do
        allow(GradingSet).to receive(:by_program_and_instructor_and_activity).and_return(grading_set)
        allow(grading_set).to receive(:complete?).and_return(false)
        @presenter = InstructorGradingStylesPresenter.new(@opts.call)
        allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return('foo')
      end

      it 'returns the grading style' do
        expect(@presenter.grading_style).to eql 'foo'
      end
    end

    context 'when grading is complete' do
      before do
        allow(GradingSet).to receive(:by_program_and_instructor_and_activity).and_return(grading_set)
        allow(grading_set).to receive(:complete?).and_return(true)
        @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      end

      context 'if the current setting is "spotcheck"' do
        before do
          allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return('spotcheck')
        end

        it 'returns spotcheck' do
          expect(@presenter.grading_style).to eql 'spotcheck'
        end
      end

      context 'if the current setting is not "spotcheck"' do
        before do
          allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return('foo')
        end

        it 'returns the current setting' do
          expect(@presenter.grading_style).to eql 'foo'
        end
      end
    end
  end

  describe '#task_type' do
    before { @presenter = InstructorGradingStylesPresenter.new(@opts.call) }

    it 'returns the task type' do
      expect(@presenter.task_type).to eql 'quux'
    end
  end

  describe '#section' do
    context 'with a course in focus' do
      before do
        @section = build_stubbed(:section)
        @focus = double(Focus)
        allow(@focus).to receive(:section).and_return(nil)
        allow(@focus).to receive(:sections).and_return([@section])
        @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      end

      it 'returns the first section' do
        # we only need the section in order to get the course's grading settings
        # so any section in the course will do
        expect(@presenter.section).to eql @section
      end
    end

    context 'with a section in focus' do
      before do
        @section = build_stubbed(:section)
        @focus = double(Focus)
        allow(@focus).to receive(:section).and_return(@section)
        @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      end

      it 'returns the section' do
        expect(@presenter.section).to eql @section
      end
    end
  end

  describe '#activity' do
    it 'returns the activity' do
      expect(Activity).to receive(:find_by_id).with(@activity.id.to_s).and_return(@activity)
      @presenter = InstructorGradingStylesPresenter.new(@opts.call)
    end
  end

  describe '#activity_list_header' do
    it 'returns the activity list header' do
      expect(@activity).to receive(:list_header).and_return('foo')
      @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      expect(@presenter.activity_list_header).to eql 'foo'
    end
  end

  describe '#classwork' do
    it 'is assigned from the activity' do
      section = double(Section)
      expect(@activity).to receive(:classwork_for).with(@instructor, section).and_return('foo')
      @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      allow(@presenter).to receive(:section).and_return(section)
      expect(@presenter.classwork).to eql 'foo'
    end
  end

  describe '#attempt' do
    it 'is assigned from the activity' do
      expect(@activity).to receive(:attempt_for).and_return('foo')

      @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      section = double(Section)
      allow(@presenter).to receive(:section).and_return(section)

      expect(@presenter.attempt).to eql 'foo'
    end
  end

  describe '#attempt_track' do
    it 'is assigned from the activity' do
      expect(@activity).to receive(:attempt_track_for).and_return('foo')

      @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      section = double(Section)
      allow(@presenter).to receive(:section).and_return(section)

      expect(@presenter.attempt_track).to eql 'foo'
    end
  end

  describe '#grading_complete?' do
    let(:grading_set) { double(GradingSet).as_null_object }

    context 'always' do
      it 'gets the grading set' do
        expect(GradingSet).to receive(:by_program_and_instructor_and_activity).with(@program,
                                                                                    @instructor, @activity).and_return(grading_set)
        @presenter = InstructorGradingStylesPresenter.new(@opts.call)
        @presenter.grading_complete?
      end
    end

    context 'when grading is complete' do
      before do
        allow(GradingSet).to receive(:by_program_and_instructor_and_activity).and_return(grading_set)
        allow(grading_set).to receive(:complete?).and_return(true)
        @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      end

      it 'returns true' do
        expect(@presenter).to be_grading_complete
      end

      it 'returns "review" for #grading_set_button_text' do
        expect(@presenter.grading_set_button_text).to eql 'review'
      end
    end

    context 'when grading is not complete' do
      before do
        allow(GradingSet).to receive(:by_program_and_instructor_and_activity).and_return(grading_set)
        allow(grading_set).to receive(:complete?).and_return(false)
        @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      end

      it 'returns false' do
        expect(@presenter).not_to be_grading_complete
      end

      it 'returns "start grading" for #grading_set_button_text' do
        expect(@presenter.grading_set_button_text).to eql 'start grading'
      end
    end

    context 'when there is no grading set' do
      before do
        allow(GradingSet).to receive(:by_program_and_instructor_and_activity).and_return(nil)
        @presenter = InstructorGradingStylesPresenter.new(@opts.call)
      end

      it 'returns false' do
        expect(@presenter).not_to be_grading_complete
      end
    end
  end

  describe '#q_by_q_disabled?' do
    let(:program) { create(:program) }
    let(:presenter) { described_class.new(opts) }
    let(:instructor) { create(:instructor) }
    let(:current_focus) { instance_double(Focus) }

    let(:opts) do
      {
        program:,
        instructor:,
        focus: current_focus,
        activity_id: activity.id.to_s,
        task_type: 'unassigned_activities_section'
      }
    end

    context 'with an instructor-created activity' do
      let(:strand) { create(:toc_entry) }
      let(:lesson) { create(:lesson, toc_entries: [strand]) }
      let(:concept) do
        create(:concept, lesson:, id: strand.location, program:)
      end

      let(:activity) do
        create(
          :instructor_created_activity,
          concept:,
          lesson:,
          toc_location: strand.location,
          title: 'IGC Test'
        )
      end

      before do
        allow(Maestro::LicenseGroup).to receive(:all).and_return([])
        allow(Activity).to receive(:find_by_id)
          .with(activity.id.to_s)
          .and_return(activity)
      end

      it 'is false if the activity has no rubric' do
        expect(presenter).not_to be_q_by_q_disabled
      end

      it 'is true if the activity has a rubric' do
        activity.update!(has_rubric: true)
        expect(presenter).to be_q_by_q_disabled
      end
    end

    context 'with a non-instructor-created activity' do
      # Activities
      let(:non_rubric_activity) { create(:activity) }
      let(:rubric_activity) { create(:activity) }
      let(:activity) { non_rubric_activity }

      # sections
      let(:no_rubric_section) { create(:section) }
      let(:mixed_rubric_section) { create(:section) }

      # students with non rubric attempts
      let(:student_1) { create(:student) }
      let(:student_2) { create(:student) }
      let(:student_3) { create(:student) }
      # student with rubric attempt
      let(:rubric_student) { create(:student) }

      context 'when activity is group chat' do
        before do
          allow(Activity).to receive(:find_by_id)
            .with(non_rubric_activity.id.to_s)
            .and_return(non_rubric_activity)
          allow(non_rubric_activity).to receive(:group_chat?).and_return(true)
          allow(presenter).to receive(:any_revision_with_rubric?).and_return(false)
          allow(current_focus).to receive(:students).and_return([])
          allow(current_focus).to receive(:section).and_return(no_rubric_section)
          allow(current_focus).to receive(:sections).and_return([no_rubric_section])
        end

        it 'returns true' do
          expect(presenter).to be_q_by_q_disabled
        end
      end

      context 'when activity is not group chat' do
        before do
          allow(Activity).to receive(:find_by_id)
            .with(non_rubric_activity.id.to_s)
            .and_return(non_rubric_activity)
          allow(Activity).to receive(:find_by_id)
            .with(rubric_activity.id.to_s)
            .and_return(rubric_activity)
          allow(non_rubric_activity).to receive(:group_chat?).and_return(false)
          allow(rubric_activity).to receive(:group_chat?).and_return(false)
        end

        # TODO: Test using a task type that is not unassigned
        context 'when activity is unassigned' do
          let(:score_1) do
            build_stubbed(
              :gb_score_action,
              activity_id: non_rubric_activity.id,
              section_id: no_rubric_section.id,
              user_id: student_1.id
            )
          end

          let(:score_2) do
            build_stubbed(
              :gb_score_action,
              activity_id: non_rubric_activity.id,
              section_id: no_rubric_section.id,
              user_id: student_2.id
            )
          end

          let(:score_3) do
            build_stubbed(
              :gb_score_action,
              activity_id: non_rubric_activity.id,
              section_id: no_rubric_section.id,
              user_id: student_3.id
            )
          end

          let(:rubric_student_score) do
            build_stubbed(
              :gb_score_action,
              activity_id: rubric_activity.id,
              section_id: mixed_rubric_section.id,
              user_id: rubric_student.id
            )
          end

          context 'when there is no activity revision with rubric' do
            before do
              # non rubric attempts
              create(
                :attempt_completed,
                activity: non_rubric_activity,
                user_id: student_1.id,
                section_id: no_rubric_section.id
              )
              create(
                :attempt_completed,
                activity: non_rubric_activity,
                user_id: student_2.id,
                section_id: no_rubric_section.id
              )
              create(
                :attempt_completed,
                activity: non_rubric_activity,
                user_id: student_3.id,
                section_id: mixed_rubric_section.id
              )

              # create doubles that stub show_rubric?
              non_rubric_double = instance_double(Activity)
              allow(non_rubric_double).to receive(:show_rubric?).and_return(false)
              # Associate specific lookups by cms_revision_id with show_rubric stubs
              allow(Activity).to(
                receive(:find_by).with(
                  cms_revision_id: non_rubric_activity.cms_revision_id
                ).once.and_return(non_rubric_double)
              )

              allow(current_focus).to receive(:students).and_return([
                                                                      student_1,
                                                                      student_2,
                                                                      student_3
                                                                    ])
              allow(current_focus).to receive(:section).and_return(no_rubric_section)
              allow(current_focus).to receive(:sections).and_return([no_rubric_section])
              allow(GradebookEngine::GradebookAPI).to receive(:find_submitted)
                .and_return([score_1, score_2, score_3])
            end

            it 'returns false' do
              expect(presenter).not_to be_q_by_q_disabled
            end
          end

          context 'when there is an activity revision with rubric' do
            before do
              opts[:activity_id] = rubric_activity.id.to_s
              # rubric attempt
              rubric_attempt = create(
                :attempt_completed,
                activity: rubric_activity,
                user_id: rubric_student.id,
                section_id: mixed_rubric_section.id
              )
              # attempt factory doesn't allow us to just pass in a cms_revision_id
              rubric_attempt.cms_revision_id = rubric_activity.cms_revision_id
              rubric_attempt.save!

              # create doubles that stub show_rubric?
              rubric_double = instance_double(Activity)

              # Associate specific lookups by cms_revision_id with show_rubric stubs
              allow(Activity).to(
                receive(:find_by).with(
                  cms_revision_id: rubric_activity.cms_revision_id
                ).once.and_return(rubric_double)
              )

              allow(rubric_double).to receive(:show_rubric?).and_return(true)
              allow(current_focus).to receive(:students)
                .and_return([student_1, student_2, student_3, rubric_student])
              allow(current_focus).to receive(:section).and_return(mixed_rubric_section)
              allow(current_focus).to receive(:sections).and_return([mixed_rubric_section])
              allow(GradebookEngine::GradebookAPI).to receive(:find_submitted)
                .and_return([score_1, score_2, score_3, rubric_student_score])
            end

            it 'returns true' do
              expect(presenter).to be_q_by_q_disabled
            end
          end
        end
      end
    end
  end

  describe 'hide_question_by_question_input?' do
    let(:presenter) { described_class.new(@opts.call) }
    let(:activity) { build_stubbed(:activity) }

    before do
      allow(Activity).to receive(:find_by_id).and_return(activity)
    end

    it 'returns false if the activity type is neither checkbox_survey, ' \
       'ai_virtual_chat, or table_activity' do
      allow(activity).to receive(:activity_type).and_return('foo')

      expect(presenter).not_to be_hide_question_by_question_input
    end

    it 'returns true if the activity type is ai_virtual_chat' do
      allow(activity).to receive(:activity_type).and_return('ai_virtual_chat')

      expect(presenter).to be_hide_question_by_question_input
    end

    it 'returns true if the activity type is checkbox_survey' do
      allow(activity).to receive(:activity_type).and_return('checkbox_survey')

      expect(presenter).to be_hide_question_by_question_input
    end

    context 'when the activity type is table_activity' do
      before do
        allow(activity).to receive(:activity_type).and_return('table_activity')
      end

      it 'returns true if there are instructor-graded questions' do
        allow(activity).to receive(:instructor_graded_questions)
          .and_return(['fake_question'])

        expect(presenter).to be_hide_question_by_question_input
      end

      it 'returns false if there are no instructor-graded questions' do
        allow(activity).to receive(:instructor_graded_questions).and_return([])

        expect(presenter).not_to be_hide_question_by_question_input
      end
    end
  end

  describe '#section_video_transcript_languages' do
    let(:presenter) { described_class.new(@opts.call) }
    let(:section) { double('Section') }
    let(:course) { double('Course') }

    before do
      allow(presenter).to receive(:section).and_return(section)
      allow(section).to receive(:course).and_return(course)
    end

    it 'returns section video transcript languages when present' do
      allow(section).to receive(:video_transcript_languages).and_return('foreign')
      allow(course).to receive(:video_transcript_languages).and_return('foreign_and_english')

      expect(presenter.section_video_transcript_languages).to eq('foreign')
    end

    it 'returns course video transcript languages when section setting is nil' do
      allow(section).to receive(:video_transcript_languages).and_return(nil)
      allow(course).to receive(:video_transcript_languages).and_return('foreign')

      expect(presenter.section_video_transcript_languages).to eq('foreign')
    end
  end

  describe '#section_video_subtitle_languages' do
    let(:presenter) { described_class.new(@opts.call) }
    let(:section) { double('Section') }
    let(:course) { double('Course') }

    before do
      allow(presenter).to receive(:section).and_return(section)
      allow(section).to receive(:course).and_return(course)
    end

    it 'returns section video subtitle languages when present' do
      allow(section).to receive(:video_subtitle_languages).and_return('foreign_and_english')
      allow(course).to receive(:video_subtitle_languages).and_return('foreign')

      expect(presenter.section_video_subtitle_languages).to eq('foreign_and_english')
    end

    it 'returns course video subtitle languages when section setting is nil' do
      allow(section).to receive(:video_subtitle_languages).and_return(nil)
      allow(course).to receive(:video_subtitle_languages).and_return('foreign_and_english')

      expect(presenter.section_video_subtitle_languages).to eq('foreign_and_english')
    end
  end

  describe '#section_audio_transcript' do
    let(:presenter) { described_class.new(@opts.call) }
    let(:section) { double('Section') }
    let(:course) { double('Course') }

    before do
      allow(presenter).to receive(:section).and_return(section)
      allow(section).to receive(:course).and_return(course)
    end

    it 'returns section audio transcript setting when not nil' do
      allow(section).to receive(:audio_transcript).and_return(true)
      allow(course).to receive(:allow_audio_transcripts).and_return(false)

      expect(presenter.section_audio_transcript).to eq(true)
    end

    it 'returns section audio transcript setting when false' do
      allow(section).to receive(:audio_transcript).and_return(false)
      allow(course).to receive(:allow_audio_transcripts).and_return(true)

      expect(presenter.section_audio_transcript).to eq(false)
    end

    it 'returns course allow_audio_transcripts when section setting is nil' do
      allow(section).to receive(:audio_transcript).and_return(nil)
      allow(course).to receive(:allow_audio_transcripts).and_return(true)

      expect(presenter.section_audio_transcript).to eq(true)
    end
  end

  describe '#audio_transcript_display' do
    let(:presenter) { described_class.new(@opts.call) }

    it 'returns "On" when section_audio_transcript is true' do
      allow(presenter).to receive(:section_audio_transcript).and_return(true)

      expect(presenter.audio_transcript_display).to eq('On')
    end

    it 'returns "Off" when section_audio_transcript is false' do
      allow(presenter).to receive(:section_audio_transcript).and_return(false)

      expect(presenter.audio_transcript_display).to eq('Off')
    end

    it 'returns "Off" when section_audio_transcript is nil' do
      allow(presenter).to receive(:section_audio_transcript).and_return(nil)

      expect(presenter.audio_transcript_display).to eq('Off')
    end
  end

  describe '#video_subtitle_languages_display' do
    let(:presenter) { described_class.new(@opts.call) }

    it 'calls display_language_name with section_video_subtitle_languages' do
      allow(presenter).to receive(:section_video_subtitle_languages).and_return('foreign')
      expect(presenter).to receive(:display_language_name).with('foreign').and_return('Spanish')

      expect(presenter.video_subtitle_languages_display).to eq('Spanish')
    end
  end

  describe '#video_transcript_languages_display' do
    let(:presenter) { described_class.new(@opts.call) }

    it 'calls display_language_name with section_video_transcript_languages' do
      allow(presenter).to receive(:section_video_transcript_languages).and_return('foreign_and_english')
      expect(presenter).to receive(:display_language_name).with('foreign_and_english').and_return('Spanish and English')

      expect(presenter.video_transcript_languages_display).to eq('Spanish and English')
    end
  end

  describe '#display_language_name' do
    let(:presenter) { described_class.new(@opts.call) }

    before do
      allow(@program).to receive(:language_name).and_return('Spanish')
      allow(@program).to receive(:language_code).and_return('es')
    end

    it 'returns program language name when setting is "foreign"' do
      expect(presenter.display_language_name('foreign')).to eq('Spanish')
    end

    context 'when setting is "foreign_and_english"' do
      it 'returns program language name when language code is "en"' do
        allow(@program).to receive(:language_code).and_return('en')
        allow(@program).to receive(:language_name).and_return('English')

        expect(presenter.display_language_name('foreign_and_english')).to eq('English')
      end

      it 'returns program language name and English when language code is not "en"' do
        allow(@program).to receive(:language_code).and_return('es')

        expect(presenter.display_language_name('foreign_and_english')).to eq('Spanish and English')
      end
    end

    it 'returns "Off" for any other setting value' do
      expect(presenter.display_language_name('some_other_value')).to eq('Off')
      expect(presenter.display_language_name(nil)).to eq('Off')
      expect(presenter.display_language_name('')).to eq('Off')
    end
  end
end
