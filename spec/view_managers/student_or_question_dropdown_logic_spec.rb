describe StudentOrQuestionDropdownLogic do
  class ClassThatUsesStudentOrQuestionDropdown
  end
  let(:student_question_logic) { ClassThatUsesStudentOrQuestionDropdown.new.extend(StudentOrQuestionDropdownLogic) }

  describe "#option_hash" do
    it "returns expected value" do
      question_or_student = double('question_or_value')
      allow(student_question_logic).to receive(:option_value).and_return('foo')
      allow(student_question_logic).to receive(:current?).and_return(true)
      allow(student_question_logic).to receive(:option_jump_to).and_return('foo')
      allow(student_question_logic).to receive(:checkmark_image_path).and_return('checkmark.svg')
      allow(student_question_logic).to receive(:option_data).and_return(other_value: 'bar')
      allow(student_question_logic).to receive(:graded?).and_return(true)
      expect(student_question_logic.option_hash(
               question_or_student)).to eq(
                 value: 'foo',
                 selected: true,
                 data: ({
                   jump_to: 'foo',
                   grade_listing_type: 'questions',
                   iconurl: 'checkmark.svg',
                   other_value: 'bar'
                 })
               )
    end
  end
end
