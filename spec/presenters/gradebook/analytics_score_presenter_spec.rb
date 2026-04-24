describe Gradebook::AnalyticsScorePresenter do
  let(:section) { create(:section) }
  let(:assignment) { create(:assignment, section:, due_date: 2.days.ago) }
  let(:student) { create(:student) }
  let(:presenter) { described_class.new(section) }

  before do
    section.students << student
  end

  describe '#display_score' do
    describe 'returned css classes for the block' do
      it 'returns nil if no score is passed' do
        presenter.display_score(student.id, assignment, nil) do |_formatted_score, css_classes|
          expect(css_classes).to be_nil
        end
      end

      it 'returns na-cell if score is N/A' do
        presenter.display_score(student.id, assignment, 'N/A') do |_formatted_score, css_classes|
          expect(css_classes).to eq 'na-cell'
        end
      end

      it 'returns no-score-cell if score is --' do
        presenter.display_score(student.id, assignment, '--') do |_formatted_score, css_classes|
          expect(css_classes).to eq 'no-score-cell'
        end
      end

      it 'returns empty string in any other cases' do
        presenter.display_score(student.id, assignment, '10') do |_formatted_score, css_classes|
          expect(css_classes).to eq ''
        end
      end

      it 'adds u-txt-ital if assignment due date has not passed' do
        assignment.update(due_date: 1.day.from_now)
        presenter.display_score(student.id, assignment, '10') do |_formatted_score, css_classes|
          expect(css_classes).to eq '  u-txt-ital'
        end
      end
    end

    describe 'score formatting' do
      it 'appends % to the score, if score is given' do
        presenter.display_score(student.id, assignment, '10') do |formatted_score, _css_classes|
          expect(formatted_score).to eq '10%'
        end
      end

      context 'when score is nil,' do
        it 'returns N/A if there is no assignment' do
          presenter.display_score(student.id, nil, nil) do |formatted_score, _css_classes|
            expect(formatted_score).to eq 'N/A'
          end
        end

        it 'returns -- if there is an assignment, but the due date has passed' do
          presenter.display_score(student.id, assignment, nil) do |formatted_score, _css_classes|
            expect(formatted_score).to eq '--'
          end
        end

        it 'returns an empty string if there is an assignment and the due date has not passed' do
          assignment.update(due_date: 1.day.from_now)
          presenter.display_score(student.id, assignment, nil) do |formatted_score, _css_classes|
            expect(formatted_score).to eq ''
          end
        end
      end
    end
  end

  describe '#display_score_change' do
    describe 'returned css classes for the block' do
      it 'returns nil if no score is passed' do
        presenter.display_score_change(nil) do |_formatted_score, css_classes|
          expect(css_classes).to be_nil
        end
      end

      it 'appends up if the change is positive' do
        presenter.display_score_change(10) do |_formatted_score, css_classes|
          expect(css_classes).to eq 'c-score-change  c-score-change--up'
        end
      end

      it 'appends down if the change is negative' do
        presenter.display_score_change(-10) do |_formatted_score, css_classes|
          expect(css_classes).to eq 'c-score-change  c-score-change--down'
        end
      end

      it 'appends none if there is no score change' do
        presenter.display_score_change(0) do |_formatted_score, css_classes|
          expect(css_classes).to eq 'c-score-change  c-score-change--none'
        end
      end
    end

    describe 'score formatting' do
      it 'returns -- if there is no score change' do
        presenter.display_score_change(nil) do |formatted_score, _css_classes|
          expect(formatted_score).to eq '--'
        end
      end

      it 'it appends % if there is a score' do
        presenter.display_score_change(0) do |formatted_score, _css_classes|
          expect(formatted_score).to eq '0%'
        end
      end

      it 'prepends + if the score change is positive' do
        presenter.display_score_change(10) do |formatted_score, _css_classes|
          expect(formatted_score).to eq '+10%'
        end
      end
    end
  end
end

