describe GradingSet do
  include RspecJsContentHelpers

  before(:each) do
    @sections = []
    @activity_id = 123
  end

  describe 'scopes' do
    describe '.by_program' do
      before do
        @the_program = create(:program)
        other_program = create(:program)
        @expected = create(:grading_set, :program => @the_program)
        create(:grading_set, :program => other_program)
      end

      it 'returns the grading sets for the program' do
        expect(GradingSet.by_program(@the_program)).to eq([@expected])
      end
    end

    describe '.by_instructor' do
      before do
        @the_instructor = create(:instructor)
        other_instructor = create(:instructor)
        @expected = create(:grading_set, :instructor => @the_instructor)
        create(:grading_set, :instructor => other_instructor)
      end

      it 'returns the grading sets for the instructor' do
        expect(GradingSet.by_instructor(@the_instructor)).to eq([@expected])
      end
    end

    describe '.by_activity' do
      before do
        @the_activity = create(:activity)
        other_activity = create(:activity)
        @expected = create(:grading_set, :activity => @the_activity)
        create(:grading_set, :activity => other_activity)
      end

      it 'returns the grading sets for the activity' do
        expect(GradingSet.by_activity(@the_activity)).to eq([@expected])
      end
    end

    describe '.by_program_and_instructor_and_activity' do
      before do
        @the_program = create(:program)
        @the_instructor = create(:instructor)
        @the_activity = create(:activity)

        other_program = create(:program)
        other_instructor = create(:instructor)
        other_activity = create(:activity)

        create(:grading_set, :program => @the_program, :instructor => other_instructor, :activity => other_activity)
        create(:grading_set, :program => other_program, :instructor => @the_instructor, :activity => other_activity)
        create(:grading_set, :program => other_program, :instructor => other_instructor, :activity => @the_activity)
        create(:grading_set, :program => other_program, :instructor => other_instructor, :activity => other_activity)
        @expected = create(:grading_set, :program => @the_program, :instructor => @the_instructor, :activity => @the_activity)
      end

      it 'returns only the grading sets for that program instructor and activity' do
        expect(GradingSet.by_program_and_instructor_and_activity(@the_program, @the_instructor, @the_activity)).to eq(@expected)
      end
    end
  end

  describe '#complete?' do
    let(:section) { build_stubbed(:section) }

    before do
      @activity = create(:activity)
      allow(Activity).to receive(:find).and_return(@activity)

      @questions = [double('Question')]
      allow(@activity).to receive(:instructor_graded_questions).and_return(@questions)

      @grading_set = create(:grading_set, :activity => @activity)
      @students = [
        create(:student),
        create(:student),
        create(:student)
      ]
      @students.each do |s|
        allow(s).to receive(:current_section_in_program)
      end

      allow(Student).to receive(:find).and_return(@students)

      allow(Attempt).to receive(:find_attempts_for_activities).and_return([])
    end

    context 'when all students have been graded' do
      before do
        allow(FeedbackItem).to receive(:find_number_of_questions_graded_for_students).and_return({
          @students[0].id => @questions.count,
          @students[1].id => @questions.count,
          @students[2].id => @questions.count
        })
      end

      it 'is true' do
        expect(@grading_set).to be_complete(section)
      end
    end

    context 'when some students have been graded' do
      before do
        allow(FeedbackItem).to receive(:find_number_of_questions_graded_for_students).and_return({
          @students[0].id => @questions.count,
          @students[1].id => 0,
          @students[2].id => @questions.count
        })
      end

      it 'is false' do
        expect(@grading_set).not_to be_complete(section)
      end
    end

    context 'when no students have been graded' do
      before do
        allow(FeedbackItem).to receive(:find_number_of_questions_graded_for_students).and_return({
          @students[0].id => 0,
          @students[1].id => 0,
          @students[2].id => 0
        })
      end

      it 'is false' do
        expect(@grading_set).not_to be_complete(section)
      end
    end
  end

  describe "#create_or_update" do
    let(:user) { create(:instructor) }
    let(:program) { create(:program) }
    let(:student_1) { create(:student) }
    let(:student_2) { create(:student) }
    let(:activity) { create(:activity) }
    let(:params) do
      {
        activity_id: activity.id,
        program_id: program.id,
        show_hide_comments: true
      }
    end

    context 'when no record exist' do
      it 'creates a new record' do
        described_class.create_or_update(
          user.id, params, [student_1.id, student_2.id]
        )
        expect(described_class.last).to have_attributes(
          user_id: user.id,
          activity_id: activity.id,
          program_id: program.id,
          student_id_list: [student_1.id, student_2.id].join(','),
          show_comments: true
        )
      end

      it 'returns the newly created record' do
        expect(described_class.create_or_update(
          user.id, params, [student_1.id, student_2.id]
        )).to eq(described_class.last)
      end

      it 'removes duplicated student ids' do
        described_class.create_or_update(
          user.id,
          params,
          [student_1.id, student_2.id, student_1.id]
        )
        expect(described_class.last.student_id_list).to eq(
          [student_1.id, student_2.id].join(',')
        )
      end
    end

    context 'when a record exists' do
      before do
        GradingSet.create(
          user_id: user.id,
          program: program,
          activity: activity,
          student_id_list: student_2.id.to_s
        )
      end

      it 'only updates the students id list' do
        described_class.create_or_update(
          user.id,
          params,
          [student_1.id, student_2.id]
        )
        expect(described_class.last).to have_attributes(
          user_id: user.id,
          activity_id: activity.id,
          program_id: program.id,
          student_id_list: [student_1.id, student_2.id].join(','),
          show_comments: false
        )
      end

      it 'returns the updated record' do
        expect(described_class.create_or_update(
          user.id, params, [student_1.id, student_2.id]
        )).to eq(described_class.last)
      end

      it 'removes duplicated student ids' do
        described_class.create_or_update(
          user.id,
          params,
          [student_1.id, student_2.id, student_1.id]
        )
        expect(described_class.last.student_id_list).to eq(
          [student_1.id, student_2.id].join(',')
        )
      end
    end
  end

  describe '#update_state' do
    let(:user) { create(:instructor) }
    let(:program) { create(:program) }
    let(:activity) { create(:activity) }

     let(:grading_set) do
      described_class.create(
          user_id: user.id,
          program: program,
          activity: activity,
          show_comments: false,
          show_student_names: true
        )
    end

    it "Updates the show comments and show student names attributes" do
      grading_set.update_state(
        show_hide_comments: 'on',
        show_hide_student_names: nil
      )
      expect(grading_set).to have_attributes(
        show_comments: true, show_student_names: false
      )
      grading_set.update_state(
        show_hide_comments: nil,
        show_hide_student_names: 'on'
      )
      expect(grading_set).to have_attributes(
        show_comments: false, show_student_names: true
      )
    end
  end

  describe '#students_to_grade' do
    let(:program) { create(:program) }
    let(:course) { create(:course, program:, end_date: 1.week.from_now) }
    let(:section) { create(:section, course:) }

    let(:students) do
      {
        first: create(:student),
        second: create(:student),
        third: create(:student)
      }
    end

    context 'when all students are eligible' do
      it 'returns students in the order specified in student_id_list' do
        student_list = [students[:third].id, students[:first].id, students[:second].id].join(',')
        grading_set = create(:grading_set, program:, student_id_list: student_list)

        students.each_value do |student|
          create(:enrollment, user: student, section:, state: 'enrolled')
        end

        results = grading_set.students_to_grade([section])

        expect(results).to eq([students[:third], students[:first], students[:second]])
      end
    end

    context 'when some students are ineligible' do
      it 'excludes dropped students and keeps order and includes marked_complete students' do
        student_list = [students[:third].id, students[:first].id, students[:second].id].join(',')
        grading_set = create(:grading_set, program:, student_id_list: student_list)

        create(:enrollment, user: students[:first], section:, state: 'dropped')
        create(:enrollment, user: students[:second], section:, state: 'enrolled')
        create(:enrollment, user: students[:third], section:, state: 'marked_complete')

        results = grading_set.students_to_grade([section])

        expect(results).to eq([students[:third], students[:second]])
      end
    end

    context 'with edge cases' do
      it 'returns empty array when no students are eligible' do
        student = create(:student)
        grading_set = create(:grading_set, program:, student_id_list: student.id.to_s)
        create(:enrollment, user: student, section:, state: 'dropped')

        results = grading_set.students_to_grade([section])

        expect(results).to be_empty
      end

      it 'handles empty student_id_list' do
        grading_set = create(:grading_set, program:, student_id_list: '')

        results = grading_set.students_to_grade([section])

        expect(results).to be_empty
      end

      it 'handles students not enrolled in provided sections' do
        student = create(:student)
        other_section = create(:section, course:)
        grading_set = create(:grading_set, program:, student_id_list: student.id.to_s)
        create(:enrollment, user: student, section: other_section, state: 'enrolled')

        results = grading_set.students_to_grade([section])

        expect(results).to be_empty
      end
    end

    context 'when multiple sections are considered' do
      it 'includes students from any of the provided sections' do
        section_2 = create(:section, course:)
        student_list = [students[:first].id, students[:second].id].join(',')
        grading_set = create(:grading_set, program:, student_id_list: student_list)

        create(:enrollment, user: students[:first], section:, state: 'enrolled')
        create(:enrollment, user: students[:second], section: section_2, state: 'enrolled')

        results = grading_set.students_to_grade([section, section_2])

        expect(results).to contain_exactly(students[:first], students[:second])
      end
    end
  end

  describe "#first_gradable_student" do
    let(:section) { build_stubbed(:section) }

    before(:each) do
      @grading_set = GradingSet.new(:student_id_list => '1,2,3')
      @activity = double(Activity)
      allow(@grading_set).to receive(:activity).and_return(@activity)
    end

    it "should return the first student where grading is not complete" do
      grading_status = { "1"=>{:status_class=>"complete", :remaining=>0},
                          "2"=>{:status_class=>"complete", :remaining=>0},
                          "3"=>{:status_class=>"ungraded", :remaining=>2} }
      allow(@grading_set).to receive(:grading_status_of_students).with(section).and_return(grading_status)
      expect(@grading_set.first_gradable_student(section)).to eq(3)
      grading_status = { "1"=>{:status_class=>"complete", :remaining=>0},
                          "2"=>{:status_class=>"incomplete", :remaining=>1},
                          "3"=>{:status_class=>"ungraded", :remaining=>2} }
      allow(@grading_set).to receive(:grading_status_of_students).with(section).and_return(grading_status)
      expect(@grading_set.first_gradable_student(section)).to eq(2)
    end

    it "should return nil if the first student is the first in the list" do
      grading_status = { "1"=>{:status_class=>"ungraded", :remaining=>2},
                         "2"=>{:status_class=>"ungraded", :remaining=>2},
                         "3"=>{:status_class=>"ungraded", :remaining=>2} }
      allow(@grading_set).to receive(:grading_status_of_students).with(section).and_return(grading_status)
      expect(@grading_set.first_gradable_student(section)).to be_nil
    end

    it "should return nil if this is a new grading set" do
      grading_status = { "1"=>{:status_class=>"ungraded", :remaining=>2},
                         "2"=>{:status_class=>"ungraded", :remaining=>2},
                         "3"=>{:status_class=>"ungraded", :remaining=>2} }
      allow(@grading_set).to receive(:grading_status_of_students).with(section).and_return(grading_status)
      expect(@grading_set.first_gradable_student(section)).to be_nil
    end

  end

  describe '#grading_status_of_questions' do
    let(:activity) { create(:activity) }
    let(:grading_set) do
      GradingSet.new(student_id_list: '1,2', activity: activity)
    end
    let(:question_01) do
      double(
        MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item,
        label: 'question_01'
      )
    end
    let(:question_02) do
      double(
        MaestroActivityEngine::ActivityContent::OpenEnded::Item,
        label: 'question_02'
      )
    end
    let(:question_03) do
      double(
        MaestroActivityEngine::ActivityContent::OpenEnded::Item,
        label: 'question_03'
      )
    end
    let(:questions) { [question_01, question_02, question_03] }
    let(:student_01) { build_stubbed(:student, id: 1) }
    let(:student_02) { build_stubbed(:student, id: 2) }
    let(:students) { [student_01, student_02] }
    let(:attempts) { [double(Attempt)] }
    let(:result) { grading_set.grading_status_of_questions(activity.questions) }

    before do
      allow(student_01).to receive(:current_section_in_program).and_return([])
      allow(student_02).to receive(:current_section_in_program).and_return([])
      allow(attempts.first).to receive(:submitted_or_completed?).and_return(true)
      allow(activity).to receive(:questions).and_return(questions)

      allow(Student).to receive(:find).and_return(students)
      allow(Attempt).to receive(:find_attempts_for_activities).and_return(attempts)
      allow(FeedbackItem).to receive(:find_number_of_students_graded_for_questions).and_return(
        question_01.label => 1,
        question_02.label => 2,
        question_03.label => 0
      )
    end

    it 'returns a hash' do
      expect(result).to be_a Hash
    end

    it 'returns incomplete when some are graded' do
      expect(result[question_01.label]).to eq(
        status_class: 'incomplete', remaining: 1
      )
    end

    it 'returns complete when all are graded' do
      expect(result[question_02.label]).to eq(
        status_class: 'complete', remaining: 0
      )
    end

    it 'returns ungraded when none are graded' do
      expect(result[question_03.label]).to eq(
        status_class: 'ungraded', remaining: 2
      )
    end

    context 'when the activity is a smart book,' do
      let(:activity) { create(:activity, activity_type: 'smart_book') }
      let(:question_01) do
        instance_double(
          Smartbook::Response,
          label: 'question_01',
          auto_graded?: false
        )
      end
      let(:question_02) do
        instance_double(
          Smartbook::Response,
          label: 'question_02',
          auto_graded?: false
        )
      end
      let(:question_03) do
        instance_double(
          Smartbook::Response,
          label: 'question_03',
          auto_graded?: false
        )
      end
      let(:question_04) do
        instance_double(
          Smartbook::Response,
          label: 'question_04',
          auto_graded?: true
        )
      end
      let(:questions) { [question_01, question_02, question_03, question_04] }
      let(:attempt_1) { instance_double(Attempt) }
      let(:attempt_2) { instance_double(Attempt) }
      let(:attempts) { [attempt_1, attempt_2] }
      let(:attempt_1_smartbook_responses) do
        instance_double(
          Smartbook::Responses,
          answered: [question_01, question_02, question_03],
          answered_by_label: {
            question_01.label => question_01,
            question_02.label => question_02,
            question_03.label => question_03
          }
        )
      end
      let(:attempt_2_smartbook_responses) do
        instance_double(
          Smartbook::Responses,
          answered: [question_01, question_02, question_03, question_04],
          answered_by_label: {
            question_01.label => question_01,
            question_02.label => question_02,
            question_03.label => question_03,
            question_04.label => question_04
          }
        )
      end

      before do
        allow(attempt_1).to receive(:smartbook_responses).and_return(
          attempt_1_smartbook_responses
        )
        allow(attempt_2).to receive(:smartbook_responses).and_return(
          attempt_2_smartbook_responses
        )
        allow(FeedbackItem).to receive(
          :find_number_of_students_graded_for_questions
        ).and_return(
          question_01.label => 1,
          question_02.label => 2,
          question_03.label => 0,
          # Auto-graded questions with no graded students
          question_04.label => 0
        )
      end

      it 'returns a hash' do
        expect(result).to be_a Hash
      end

      it 'returns incomplete when some are graded' do
        expect(result[question_01.label]).to eq(
          status_class: 'incomplete', remaining: 1
        )
      end

      it 'returns complete when all are graded' do
        expect(result[question_02.label]).to eq(
          status_class: 'complete', remaining: 0
        )
      end

      it 'returns ungraded when none are graded' do
        expect(result[question_03.label]).to eq(
          status_class: 'ungraded', remaining: 2
        )
      end

      it 'returns complete for auto-graded questions' do
        expect(result[question_04.label]).to eq(
          status_class: 'complete', remaining: 0
        )
      end
    end
  end

  describe "#points_earned_for_student_on_question" do
    before(:each) do
      @grading_set = GradingSet.new(:student_id_list => '1,2,3')
      allow(@grading_set).to receive(:activity).and_return([@activity])
      @student = double(Student, :id => 1)
      @question = double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, :label => 'question_01')
      @attempt = double(Attempt)
      @feedback_with_points = double(FeedbackItem, :points_earned => 10)
      @feedback_without_points = double(FeedbackItem, :points_earned => 0)
      @section = build_stubbed(:section)
      expect(Attempt).to receive(:find_by_student_section_and_activity).and_return(@attempt)
    end

    context "when the student has a score for that question" do
      it "should return the number of points the student earned on the question" do
        expect(FeedbackItem).to receive(:find_student_points_earned_for_question).with(@question, @student.id, @attempt).and_return(@feedback_with_points)
        result = @grading_set.points_earned_for_student_on_question(@question, @student, @section)
        expect(result).to eq(10)
      end
    end

    context "when the student does not have a score for that question" do
      it "should return zero" do
        expect(FeedbackItem).to receive(:find_student_points_earned_for_question).with(@question, @student.id, @attempt).and_return(@feedback_without_points)
        result = @grading_set.points_earned_for_student_on_question(@question, @student, @section)
        expect(result).to eq(0)
      end
    end
  end

  describe "#comment_for_student_on_question" do
    before(:each) do
      @grading_set = GradingSet.new(:student_id_list => '1,2,3')
      allow(@grading_set).to receive(:activity).and_return([@activity])
      @student = double(Student, :id => 1)
      @question = double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, :label => 'question_01')
      @attempt = double(Attempt)
      @feedback_with_comment = double(FeedbackItem, :comment => 'comment')
      @section = build_stubbed(:section)
      expect(Attempt).to receive(:find_by_student_section_and_activity).and_return(@attempt)
    end

    it "should return the comment for the question" do
      allow(FeedbackItem).to receive(:find_comment_for_question).with(@question, @student.id, @attempt).and_return(@feedback_with_comment)
      expect(FeedbackItem).to receive(:find_comment_for_question).with(@question, @student.id, @attempt).and_return(@feedback_with_comment)
      result = @grading_set.comment_for_student_on_question(@question, @student, @section)
      expect(result).to eq('comment')
    end
  end

  describe "#inline_corrections_for_student_on_question" do
    before(:each) do
      @grading_set = GradingSet.new(:student_id_list => '1,2,3')
      allow(@grading_set).to receive(:activity).and_return([@activity])
      @student = double(Student, :id => 1)
      @question = double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, :label => 'question_01')
      @attempt = double(Attempt)
      @feedback_with_inline_corrections = double(FeedbackItem, :inline_corrections => 'corrections')
      @section = build_stubbed(:section)
      expect(Attempt).to receive(:find_by_student_section_and_activity).and_return(@attempt)
    end

    it "should return the inline corrections for the question" do
      allow(FeedbackItem).to receive(:find_inline_corrections_for_question).with(@question, @student.id, @attempt).and_return(@feedback_with_inline_corrections)
      expect(FeedbackItem).to receive(:find_inline_corrections_for_question).with(@question, @student.id, @attempt).and_return(@feedback_with_inline_corrections)
      result = @grading_set.inline_corrections_for_student_on_question(@question, @student, @section)
      expect(result).to eq('corrections')
    end
  end

  describe "#feedback_for_student_on_question" do
    before(:each) do
      @grading_set = GradingSet.new(:student_id_list => '1,2,3')
      allow(@grading_set).to receive(:activity).and_return([@activity])
      @student = double(Student, :id => 1)
      @question = double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, :label => 'question_01')
      @attempt = double(Attempt)
      @feedback = double(FeedbackItem, :inline_corrections => 'corrections', :comment => 'comment', :points_earned => 10)
      @section = build_stubbed(:section)
      expect(Attempt).to receive(:find_by_student_section_and_activity).and_return(@attempt)
    end

    it "should return the inline corrections for the question" do
      expect(FeedbackItem).to receive(:find_corrections_and_comment_and_points_earned_and_recording_for_question).with(@question, @student.id, @attempt).and_return(@feedback)
      result = @grading_set.feedback_for_student_on_question(@question, @student, @section)
      expect(result.inline_corrections).to eq('corrections')
      expect(result.comment).to eq('comment')
      expect(result.points_earned).to eq(10)
    end
  end

  describe "#grading_status_of_students" do
    # this is a stand-in for a MaestroActivityEngine::ActivityContent::OpenEnded::Item object
    OpenEndedItem = Struct.new(:label, :id)
    let(:section) { build_stubbed(:section) }
    let(:activity) { create(:activity) }
    let(:grading_set) do
      GradingSet.new(student_id_list: '1,2', activity: activity)
    end
    let(:question_01) do
      double(MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item, label: 'question_01')
    end
    let(:question_02) do
      double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, label: 'question_02')
    end
    let(:question_03) do
      double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, label: 'question_03')
    end
    let(:question_04) do
      double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, label: 'question_04')
    end
    let(:question_05) do
      double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, label: 'question_05')
    end
    let(:questions) { [question_01, question_02, question_03, question_04, question_05] }
    let(:student_01) { build_stubbed(:student, id: 1) }
    let(:student_02) { build_stubbed(:student, id: 2) }
    let(:student_03) { build_stubbed(:student, id: 3) }
    let(:students) { [student_01, student_02, student_03] }
    let(:attempts) { [instance_double(Attempt, status_code: 2), instance_double(Attempt, status_code: 2)] }
    let(:result) { grading_set.grading_status_of_students(section) }

    before do
      allow(student_01).to receive(:current_section_in_program).and_return([])
      allow(student_02).to receive(:current_section_in_program).and_return([])
      allow(student_03).to receive(:current_section_in_program).and_return([])
      attempts.each do |attempt|
        allow(attempt).to receive(:submitted_or_completed?).and_return(true)
      end
      allow(Student).to receive(:find).and_return(students)
      allow(Attempt).to receive(:find_attempts_for_activities).and_return(attempts)
      allow(Activity).to receive(:find).with(activity.id).and_return(activity)
      allow(activity).to receive(:instructor_graded_questions).and_return(questions)
      allow(FeedbackItem).to receive(:find_number_of_questions_graded_for_students).and_return(
        student_01.id.to_s => 4,
        student_02.id.to_s => 5,
        student_03.id.to_s => 0
      )
    end

    it 'returns a hash' do
      expect(result).to be_a Hash
    end

    it 'returns incomplete when some questions for a student are graded' do
      expect(result[student_01.id.to_s]).to eq(
        status_class: 'incomplete', remaining: 1
      )
    end

    it 'returns complete when all questions for a student are graded' do
      expect(result[student_02.id.to_s]).to eq(
        status_class: 'complete', remaining: 0
      )
    end

    it 'returns ungraded when no questions for a student are graded' do
      expect(result[student_03.id.to_s]).to eq(
        status_class: 'ungraded', remaining: 5
      )
    end

    it 'finds the attempts for the given section' do
      grading_set.grading_status_of_students(section)
      expect(Attempt).to have_received(:find_attempts_for_activities).with(
        [1, 2], section, [activity],
        status_code: [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED]
      )
    end
  end

  describe "#owned_by?" do
    let(:instructor_1) { create(:instructor) }
    let(:instructor_2) { create(:instructor) }
    let(:grading_set) { create(:grading_set, :instructor => instructor_1) }

    it "returns false when user_id doesn't matches given user" do
      grading_set.owned_by?(instructor_2)
    end

    it "returns true when user_id matches given user" do
      grading_set.owned_by?(instructor_1)
    end
  end

  describe "#student_ids" do
    it "should return an array of student ids" do
      expect(GradingSet.new(:student_id_list => '1,2,3').student_ids).to eq([1,2,3])
    end
  end

  describe "#grade_all_full_credit" do
    let(:section) { build_stubbed(:section) }
    let(:student) { build_stubbed(:student, :id => 123) }
    let(:activity) { create(:activity) }
    let(:question_1) { double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, :label => 'question_01', :points_possible => 10) }
    let(:question_2) { double(MaestroActivityEngine::ActivityContent::OpenEnded::Item, :label => 'question_02', :points_possible => 10) }
    let(:submitted_attempt) { build_stubbed(:attempt, :activity_id => activity.id,
                                                     :user_id => student,
                                                     :section_id => section,
                                                     :status_code => AttemptStatus::CODE_COMPLETED) }
    let(:grading_set) { GradingSet.create(:program_id => build_stubbed(:program),
                                          activity: activity,
                                          :student_id_list => student.id.to_s)}
    let(:expected_fb_params_1) { {:points_earned => question_1.points_possible,
                                  :question_label => question_1.label } }
    let(:expected_fb_params_2) { {:points_earned => question_2.points_possible,
                                  :question_label => question_2.label } }
    let(:cartridge_consumer_guid) { SecureRandom.uuid }
    let(:cartridge_params) { { cartridge_consumer_guid: cartridge_consumer_guid } }

    before do
      allow(Attempt).to receive(:find_submitted_attempts_for_activities).and_return([submitted_attempt])
      allow(submitted_attempt).to receive(:instructor_graded_questions).and_return([question_1, question_2])
      allow(submitted_attempt).to receive(:feedback_item).with(question_1.label).and_return(nil)
      allow(submitted_attempt).to receive(:feedback_item).with(question_2.label).and_return(nil)
      allow(submitted_attempt).to receive(:student).and_return(student)
      allow(grading_set).to receive(:activity).and_return(activity)
      allow(FeedbackItem).to receive(:submit)
    end

    it "finds submitted attempts" do
      expect(Attempt).to receive(:find_submitted_attempts_for_activities).with([student], [section], [activity])
      grading_set.grade_all_full_credit(
        sections: [section],
        cartridge_params: cartridge_params,
        students: [student]
      )
    end

    it "adds feedback items for each question" do
      expect(FeedbackItem).to receive(:submit).with(hash_including(expected_fb_params_1))
      expect(FeedbackItem).to receive(:submit).with(hash_including(expected_fb_params_2))
      grading_set.grade_all_full_credit(
        sections: [section],
        cartridge_params: cartridge_params,
        students: [student]
      )
    end

    it "does not overwrite graded questions" do
      allow(submitted_attempt).to receive(:feedback_item).with(question_2.label).and_return(double(FeedbackItem, :points_earned => 9.5))
      expect(FeedbackItem).to receive(:submit).with(hash_including(expected_fb_params_1))
      expect(FeedbackItem).not_to receive(:submit).with(hash_including(expected_fb_params_2))
      grading_set.grade_all_full_credit(
        sections: [section],
        cartridge_params: cartridge_params,
        students: [student]
      )
    end
  end

  describe '#grade_all_comment' do
    let(:section) { create(:section) }
    let(:student) { create(:student) }
    let(:activity) { create(:activity) }
    let(:user) { create(:instructor) }
    let(:submitted_attempt) do
      create(
        :attempt,
        activity_id: activity.id,
        user_id: student.id,
        section_id: section.id,
        status_code: AttemptStatus::CODE_COMPLETED
      )
    end
    let(:grading_set) do
      described_class.create(
        program_id: create(:program),
        activity_id: activity.id,
        student_id_list: student.id.to_s
      )
    end
    let(:comment) { 'valid comment' }
    let(:expected_fb_params) { { comment: comment } }
    let(:cartridge_consumer_guid) { SecureRandom.uuid }
    let(:cartridge_params) { { cartridge_consumer_guid: cartridge_consumer_guid } }

    before do
      allow(Attempt).to receive(
        :find_submitted_attempts_for_activities
      ).and_return([submitted_attempt])
      allow(FeedbackItem).to receive(:submit)
    end

    it 'finds submitted attempts' do
      grading_set.comment_all(
        comment: comment,
        sections: [section],
        cartridge_params: cartridge_params,
        students: [student]
      )

      expect(Attempt).to have_received(
        :find_submitted_attempts_for_activities
      ).with(
        [student],
        [section],
        [activity]
      )
    end

    it 'adds a general feedback item for the activity' do
      grading_set.comment_all(
        comment: comment,
        sections: [section],
        cartridge_params: cartridge_params,
        students: [student]
      )

      expect(FeedbackItem).to have_received(:submit).with(
        student: student,
        section: section,
        activity: activity,
        comment: comment,
        attempt: submitted_attempt,
        cartridge_params: cartridge_params
      )
    end
  end
end
