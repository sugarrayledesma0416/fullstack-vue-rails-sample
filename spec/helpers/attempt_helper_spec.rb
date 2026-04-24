describe AttemptHelper do
  include AttemptHelper
  include GradebookHelper

  let(:activity) { build_stubbed(:activity, :max_attempts => 1, :submittable => true) }
  let(:score) { build_stubbed(:score) }
  let(:section) { build_stubbed(:section) }
  let(:helper) { Object.new.extend(AttemptHelper) }

  context "#format_scoring_ruleset" do
    it "should create an unordered list items styled by their status" do
      scoring_ruleset = build_stubbed(:scoring_ruleset,
                                      :ignore_capitalization => true,
                                      :ignore_accents        => false,
                                      :ignore_punctuation    => false)
      results = format_scoring_ruleset(scoring_ruleset)
      expect(results).to have_selector(
        'li[class="inactive capitalization"][title="Capitalization"]',
        text: 'Incorrect capitalization WILL NOT affect your score.'
      )
      expect(results).to have_selector(
        'li[class="active accents"][title="Accents"]',
        text: 'Extra or missing accent marks WILL affect your score.'
      )
      expect(results).to have_selector(
        'li[class="active punctuation"][title="Punctuation"]',
        text: 'Punctuation errors WILL affect your score.'
      )
    end
  end

  describe 'formatting the attempt status' do
    describe '#format_attempt_status_from_gradebook' do
      let(:presenter) { double() }
      let(:grade) { double() }
      let(:status) { double() }

      before do
        allow(presenter).to receive(:grade_for) { grade }
        allow(helper).to receive(:format_grade)
        allow(helper).to receive(:status_string)
      end

      context 'when the activity is gradeable' do
        context 'and the student has submitted the activity' do
          it 'formats the score for the assignment grade' do
            allow(grade).to receive(:submitted?).and_return(true)
            allow(grade).to receive(:pending?).and_return(true)

            helper.format_attempt_status_from_gradebook(status: nil, presenter: presenter, activity: activity)
            expect(helper).to have_received(:format_grade).with(grade, activity)
          end
        end

        context 'and the student has not submitted the activity' do
          it 'returns a string based on the attempt status' do
            allow(grade).to receive(:submitted?).and_return(false)

            helper.format_attempt_status_from_gradebook(status: status, presenter: presenter, activity: activity)
            expect(helper).to have_received(:status_string).with(status)
          end
        end
      end

      context 'when the activity is not gradeable' do
        it 'returns a string based on the attempt status' do
          allow(activity).to receive(:gradable?).and_return(false)
          helper.format_attempt_status_from_gradebook(status: status, presenter: nil, activity: activity)
          expect(helper).to have_received(:status_string).with(status)
        end
      end
    end

    describe '#format_grade' do
      def link_text(grade)
        "<a class=\"activity_link\" href=\"/sections/#{grade.section.id}/activities/#{grade.level_id}\">#{grade.formatted_score}%</a>"
      end

      def link_text_late(grade)
        "<a class=\"late_score activity_link\" href=\"/sections/#{grade.section.id}/activities/#{grade.level_id}\">#{grade.formatted_score}%</a>"
      end

      let(:grade) { double() }
      let(:section) { double() }
      let(:activity) { double() }
      let(:activity_id) { 5678 }

      context 'when there is a submission' do
        before do
          allow(section).to receive(:id).and_return 1234
          allow(grade).to receive(:section).and_return section
          allow(grade).to receive(:level_id).and_return activity_id
          allow(grade).to receive(:formatted_score).and_return '90'
          allow(activity).to receive(:to_s).and_return activity_id.to_s
        end

        context 'and the assignment is not late' do
          it 'returns a link to the activity with the formatted score as the link text' do
            allow(grade).to receive(:submitted?).and_return true
            allow(grade).to receive(:late?).and_return false
            allow(grade).to receive(:pending?).and_return false
            allow(grade).to receive(:partial_pending?).and_return false

            expected_string = link_text(grade)
            expect(format_grade(grade, activity)).to eq expected_string
          end
        end

        context 'and the assignment is late' do
          it 'returns a link to the activity with the formatted score as the link text and a class of late_score' do
            allow(grade).to receive(:submitted?).and_return true
            allow(grade).to receive(:late?).and_return true
            allow(grade).to receive(:pending?).and_return false
            allow(grade).to receive(:partial_pending?).and_return false

            expected_string = link_text_late(grade)
            expect(format_grade(grade, activity)).to eq expected_string
          end
        end

        context 'and the assignment is pending' do
          it 'returns the string "Pending"' do
            allow(grade).to receive(:submitted?).and_return true
            allow(grade).to receive(:pending?).and_return true
            allow(grade).to receive(:partial_pending?).and_return false

            expect(helper.format_grade(grade, activity)).to eq 'Pending'
          end
        end

        context 'and the assignment is partially pending' do
          it 'returns the string "Pending"' do
            allow(grade).to receive(:submitted?).and_return true
            allow(grade).to receive(:pending?).and_return false
            allow(grade).to receive(:partial_pending?).and_return true

            expect(helper.format_grade(grade, activity)).to eq 'Pending'
          end
        end
      end

      # NOTE: If the assignment is due, the score value should be handled correctly
      #   by the GradebookEngine grade object.
      #
      #   If the assignment has not been submitted, format_grade should not be called.
    end
  end

  describe "#assessment_ruleset" do
    let(:ruleset) { double('ScoringRuleset') }

    # Note: status = false means feature is NOT disabled
    it "returns active icons when strictness is enabled" do
      allow(ruleset).to receive(:respected_features_list).and_return([ { :text => 'accents', :status => false },
                                                          { :text => 'punctuation', :status => false } ])
      results = Nokogiri::XML.parse(assessment_ruleset(ruleset))
      items = results.xpath('//li')

      expect(items.first.text).to eq("Extra or missing accent marks WILL affect your score.")
      expect(items.first.attribute('class').value).to eq('active accents')
      expect(items.first.attribute('title').value).to eq('Accents')

      expect(items.last.text).to eq("Punctuation errors WILL affect your score.")
      expect(items.last.attribute('class').value).to eq('active punctuation')
      expect(items.last.attribute('title').value).to eq('Punctuation')
    end

    # Note: status = true means feature is disabled
    it "returns inactive icons when strictness is disabled" do
      allow(ruleset).to receive(:respected_features_list).and_return([ { :text => 'capitalization', :status => true } ])
      results = Nokogiri::XML.parse(assessment_ruleset(ruleset))
      item = results.xpath('//li')

      expect(item.text).to eq("Incorrect capitalization WILL NOT affect your score.")
      expect(item.attribute('class').value).to eq('inactive capitalization')
      expect(item.attribute('title').value).to eq('Capitalization')
    end

    it "return nil when there is no ruleset" do
      expect(assessment_ruleset(nil)).to be_nil
    end
  end
end
