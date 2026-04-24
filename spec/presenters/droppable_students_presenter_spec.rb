describe DroppableStudentsPresenter do

  describe "#droppable_students_info" do
    let(:student) { build_stubbed(:student) }
    let(:course) { build_stubbed(:course) }
    let(:section) { build_stubbed(:section, :course => course ) }
    let(:enrollment) { build_stubbed(:enrollment, :user => student, :section => section) }

    it 'builds an array of student info' do
      allow(enrollment).to receive(:course).and_return(course)
      presenter = described_class.new([student], [section])
      allow(presenter).to receive(:droppable_enrollments).and_return([enrollment])
      expect(presenter.droppable_students_info.first[:user]).to eql(enrollment.user)
      expect(presenter.droppable_students_info.first[:course]).to eql(enrollment.course)
      expect(presenter.droppable_students_info.first[:section]).to eql(enrollment.section)
      expect(presenter.droppable_students_info.first[:json]).to eq({user_id: enrollment.user.id, section_id: enrollment.section.id, blocked: false}.to_json)
    end
  end

  describe "#droppable_enrollments" do
    it 'returns active and completed enrollments' do
      section = create(:section)
      user = create(:student)

      enrollment_1 = create(:enrollment, :user => user, :section => section)
      enrollment_2 = create(:transferred_enrollment, :user => user, :section => section)
      enrollment_3 = create(:enrollment, :user => user, :section => section, :state => 'marked_complete')
      enrollment_4 = create(:dropped_enrollment, :user => user, :section => section)
      presenter = DroppableStudentsPresenter.new([user], [section])
      expect(presenter.droppable_enrollments.to_a).to eql([enrollment_1, enrollment_3])
    end

    it "returns enrollments for the given users and sections" do
      section_1 = create(:section)
      section_2 = create(:section)
      user_1 = create(:student)
      user_2 = create(:student)
      user_3 = create(:student)

      enrollment_1 = create(:enrollment, :user => user_1, :section => section_1)
      enrollment_2 = create(:enrollment, :user => user_2, :section => section_1)
      enrollment_3 = create(:enrollment, :user => user_3, :section => section_1)
      presenter = DroppableStudentsPresenter.new([user_1], [section_1])
      expect(presenter.droppable_enrollments.to_a).to eql([enrollment_1])
    end
  end

  describe 'Methods that check blocked enrollments' do
    let(:section) { create(:section) }
    let(:student_1) { create(:student, last_name: 'Aaa') }
    let(:student_2) { create(:student, last_name: 'Bbb') }

    before do
      create(:enrollment, user: student_1, section: section, blocked: true)
      create(:enrollment, user: student_2, section: section, blocked: false)
    end

    describe '#enrollment_blocked_text' do
      it 'returns a text information when enrollment is blocked' do
        presenter = described_class.new([student_1, student_2], [section])
        expect(presenter.enrollment_blocked_text(0)).to eq(
          described_class::ENROLLMENT_BLOCKED_CALL
        )
      end

      it 'returns an empty string when enrollment is not blocked' do
        presenter = described_class.new([student_1, student_2], [section])
        expect(presenter.enrollment_blocked_text(1)).to eq('')
      end
    end

    describe '#checkbox_row_disabled' do
      it 'returns a "is-disabled" when enrollment is blocked' do
        presenter = described_class.new([student_1, student_2], [section])
        expect(presenter.checkbox_row_disabled(0)).to eq('is-disabled')
      end

      it 'returns an empty string when enrollment is not blocked' do
        presenter = described_class.new([student_1, student_2], [section])
        expect(presenter.checkbox_row_disabled(1)).to eq('')
      end
    end

    describe '#enrollment_blocked?' do
      # rubocop:disable RSpec/PredicateMatcher
      # because expect(presenter).to be_enrollment_blocked(0) doesn't make sense
      it 'is true when enrollment is blocked' do
        presenter = described_class.new([student_1, student_2], [section])
        expect(presenter.enrollment_blocked?(0)).to be_truthy
      end

      it 'is false when enrollment is not blocked' do
        presenter = described_class.new([student_1, student_2], [section])
        expect(presenter.enrollment_blocked?(1)).to be_falsey
      end
      # rubocop:enable RSpec/PredicateMatcher
    end
  end
end
