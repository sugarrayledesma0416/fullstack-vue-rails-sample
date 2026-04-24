describe AssessmentHelper do
  include AssessmentHelper
  include ScoreHelper
  include GradebookHelper

  let(:section)    { build_stubbed(:section) }
  let(:assessment) { double('assessment', :concept_name => 'some name', :lesson_display_name => 'some lesson name', student_title: 'student title') }
  let(:assignment) { build_stubbed(:assignment) }
  let(:score) do
    instance_double(::GradebookEngine::AssignmentGrade,
                    net_ratio: 0.0, pending?: false, partial_pending?: false)
  end

  before do
    allow(assignment).to receive(:assignable).and_return(assessment)
  end

  describe "#format_assessment_assignment_title" do

    context 'when assigment grade has been released' do
      before do
        allow(assignment).to receive(:assessment_grade_available?).and_return(true)
        allow(assessment).to receive(:student_display_title).and_return('student title')
      end

      context "and there is score " do
        context "and the score is not pending" do
          it "renders the activity title as link" do
             allow(score).to receive(:pending?).and_return(false)
             expect(format_assessment_assignment_title(assignment, section, score)).to have_selector("a[href='#{section_activity_path(section, assignment.assignable)}']", text: 'student title')
          end
        end

        context "and the score is pending" do
          it "renders the activity title inside a span" do
            allow(score).to receive(:pending?).and_return(true)
            expect(format_assessment_assignment_title(assignment, section, score)).to have_selector('span', text: 'student title')
          end
        end
      end

      context "and there is no score yet" do
         it "should render the activity title inside a span" do
          expect(format_assessment_assignment_title(assignment, section, nil, :title => 'Some Title')).to have_selector('span[title="Some Title"]', text: 'student title')
        end
      end
    end

    context 'when assigment grade has not been released' do
      before do
        allow(assignment).to receive(:assessment_grade_available?).and_return(false)
        allow(assessment).to receive(:student_display_title).and_return('student title')
      end

      it "renders the activity title inside a span" do
        expect(format_assessment_assignment_title(assignment, section, nil)).to have_selector('span', text: 'student title')
      end

      it "includes additional html options if these are passed" do
        expect(format_assessment_assignment_title(assignment, section, nil, :title => 'Some Title')).to have_selector('span[title="Some Title"]', text: 'student title')
      end
    end
  end

  describe "#format_assessment_assignment_score_as_link" do

    context 'when assigment grade has been released' do
      before { allow(assignment).to receive(:assessment_grade_available?).and_return(true) }

      context "and there is a score" do
        context "and the score is not pending" do
          it "renders the activity grade as link to the activity" do
            allow(score).to receive(:pending?).and_return(false)
            allow(score).to receive(:net_ratio).and_return(0.982)
            expect(format_assessment_assignment_score_as_link(assignment, section, score)).to have_selector("a[href='#{section_activity_path(section, assignment.assignable)}']", text: '98.2%')
          end
        end

        context "and the score is pending" do
          it "renders the activity grade inside a span" do
            allow(score).to receive(:pending?).and_return(true)
            expect(format_assessment_assignment_score_as_link(assignment, section, score, :title => 'Some Title')).to have_selector(:xpath, './/span[@title="Some Title"][text()="Pending"]')
          end
        end
      end

      context "and there is no score yet" do
        it "should render the activity grade as link to the activity" do
          expect(format_assessment_assignment_score_as_link(assignment, section, nil, :title => 'Some Title')).to have_selector(:xpath, './/span[@title="Some Title"][text()="Pending"]')
        end
      end
    end

    context 'when assigment grade has not been released' do
      before { allow(assignment).to receive(:assessment_grade_available?).and_return(false) }

      it "should render the score text without a link" do
        expect(format_assessment_assignment_score_as_link(assignment, section, score)).to have_selector(:xpath, './/span[text()="Pending"]')
      end

      it "should include additional html options if these are passed" do
        expect(format_assessment_assignment_score_as_link(assignment, section, score, :title => 'Some Title')).to have_selector(:xpath, './/span[@title="Some Title"][text()="Pending"]')
      end
    end
  end

  describe "#format_assessment_assignment_title_text" do

    it "returns a string containing activity lesson_label and concept name values" do
      allow(assessment).to receive(:student_display_title).and_return('some lesson name: student title')
      expect(format_assessment_assignment_title_text(assessment)).to eql "#{assessment.lesson_display_name}: student title"
    end
  end

  describe "#pretty_print_time" do
    context 'seconds = 30' do
      it 'outputs: 30 seconds' do
        expect(pretty_print_time(30)).to eq('30 seconds')
      end
    end

    context 'seconds = 1800' do
      it 'outputs: 30 minutes' do
        expect(pretty_print_time(1800)).to eq('30 minutes')
      end
    end

    context 'seconds = 108000' do
      it 'outputs: 30 hours' do
        expect(pretty_print_time(108000)).to eq('30 hours')
      end
    end

    context 'seconds = 1830' do
      it 'outputs: 30 minutes 30 seconds' do
        expect(pretty_print_time(1830)).to eq('30 minutes 30 seconds')
      end
    end

    context 'seconds = 109800' do
      it 'outputs: 30 hours 30 minutes' do
        expect(pretty_print_time(109800)).to eq('30 hours 30 minutes')
      end
    end

    context 'seconds = 109830' do
      it 'outputs: 30 hours 30 minutes 30 seconds' do
        expect(pretty_print_time(109830)).to eq('30 hours 30 minutes 30 seconds')
      end
    end

    context 'seconds = 3661' do
      it 'outputs: 1 hour 1 minute 1 second' do
        expect(pretty_print_time(3661)).to eq('1 hour 1 minute 1 second')
      end
    end
  end

end
