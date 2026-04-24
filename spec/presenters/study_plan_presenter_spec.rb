describe StudyPlanPresenter do
  let(:user) { create(:user) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:section) { create(:section) }
  let(:lesson) { create(:lesson_with_toc_entries, unit: unit) }
  let(:activity) do
    create(:activity,
           lesson:,
           activity_type: 'diagnostic_v2',
           cms_activity_id: 1,
           toc_location: lesson.strands.last.location)
  end
  let(:cms_revision_id) { 744_128 }
  let(:attempt) do
    create(
      :attempt,
      activity: activity,
      cms_revision_id: cms_revision_id,
      section: section
    )
  end
  let(:presenter) { described_class.new(attempt, activity, user.id, true, user) }
  let(:diagnostic_v2_xml) { File.open('spec/fixtures/xml/diagnostic_v2.xml') }
  let(:doc) { Nokogiri::XML.parse(diagnostic_v2_xml) }
  let(:linked_media_item) { LinkedMediaItemStub }
  let(:content_object) do
    MaestroActivityEngine::ActivityParser.create_parser(doc.to_s, linked_media_item).parse
  end

  before do
    allow(activity).to receive(:content_object).and_return(content_object)
  end

  describe '#concepts' do
    it 'returns StudyPlan::ConceptWithScores instances' do
      create(
        :study_plan_concept,
        activity_id: activity.id,
        cms_revision_id: cms_revision_id,
        program_id: program.id
      )
      concepts = presenter.concepts

      expect(concepts.first).to be_a StudyPlan::ConceptWithScores
    end
  end

  describe '#redirect_notice' do
    context 'when the activity attempt is not complete' do
      let(:attempt) { create(:attempt, activity: activity) }
      let(:activity) { create(:activity, activity_type: activity_type) }

      context 'when the activity is a study plan practice test,' do
        let(:activity_type) { 'study_plan_practice_test' }

        it 'shows a notice to complete the activity' do
          presenter = described_class.new(attempt, activity, user.id, true)
          expect(presenter.redirect_notice).to eq(
            described_class::STUDY_PLAN_REDIRECT_NOTICE
          )
        end
      end

      context 'with a non study plan type activity,' do
        let(:activity_type) { 'fill_in_the_blanks' }

        it 'shows a notice of redirected to activity' do
          presenter = described_class.new(attempt, activity, user.id, true)
          expect(presenter.redirect_notice).to eq(
            described_class::NON_STUDY_PLAN_REDIRECT_NOTICE
          )
        end
      end
    end

    context 'when the activity attempt is complete' do
      let(:attempt) { create(:attempt_completed, activity: activity) }
      let(:activity) { create(:activity, activity_type: activity_type) }

      context 'when the activity is a study plan practice test,' do
        let(:activity_type) { 'study_plan_practice_test' }

        it 'shows a noticed of redirected to study plan' do
          presenter = described_class.new(attempt, activity, user.id, true)
          expect(presenter.redirect_notice).to eq(
            described_class::COMPLETED_STUDY_PLAN_REDIRECT_NOTICE
          )
        end
      end

      context 'with a non study plan type activity,' do
        let(:activity_type) { 'fill_in_the_blanks' }

        it 'returns false' do
          presenter = described_class.new(attempt, activity, user.id, true)
          expect(presenter.redirect_notice).to eq(
            described_class::NON_STUDY_PLAN_REDIRECT_NOTICE
          )
        end
      end
    end
  end

  describe '#show_study_plan?' do
    context 'with a completed diagnostic_v2 activity assignment' do
      let(:activity) { create(:activity, activity_type: 'diagnostic_v2') }
      let(:attempt) { create(:attempt_completed, activity: activity, section: section) }
      let(:presenter) { described_class.new(attempt, activity, user.id, true) }

      it 'is true when there is a formative activity' do
        allow(presenter.activity).to receive(:content_object).and_return(content_object)
        expect(presenter).to be_show_study_plan
      end

      it 'is false when there is no formative activity' do
        allow(content_object).to receive(:formative_activities).and_return([])
        allow(presenter.activity).to receive(:content_object).and_return(content_object)
        expect(presenter).not_to be_show_study_plan
      end
    end

    context 'when the activity is a study plan practice test' do
      let(:activity) { create(:activity, activity_type: 'study_plan_practice_test') }

      it 'is true when the assignment is completed' do
        attempt = create(:attempt_completed, activity: activity, section: section)
        presenter = described_class.new(attempt, activity, user.id, true)
        expect(presenter).to be_show_study_plan
      end

      it 'is false the assignment has not been completed' do
        attempt = create(:attempt_opened, activity: activity, section: section)
        presenter = described_class.new(attempt, activity, user.id, true)
        expect(presenter).not_to be_show_study_plan
      end
    end

    it 'is false when the activity is not a study plan practice test' do
      activity = create(:activity, activity_type: 'fill_in_the_blanks')
      attempt = create(:attempt_completed, activity: activity, section: section)
      presenter = described_class.new(attempt, activity, user.id, true)
      expect(presenter).not_to be_show_study_plan
    end
  end

  describe '#study_plan_version' do
    let(:attempt) { create(:attempt_completed, activity: activity, section: section) }

    it 'shows v1 with non diagnostic v2 activity type' do
      activity = create(:activity, activity_type: 'study_plan_practice_test')
      presenter = described_class.new(attempt, activity, user.id, true)
      expect(presenter.study_plan_version).to eq('v1')
    end

    it 'shows v2 with a diagnostic v2 activity type' do
      activity = create(:activity, activity_type: 'diagnostic_v2')
      presenter = described_class.new(attempt, activity, user.id, true)
      expect(presenter.study_plan_version).to eq('v2')
    end
  end

  describe '#columns' do
    let(:formative_activity_titles) { presenter.formative_activities.map(&:title) }

    before do
      allow(presenter.activity).to receive(:content_object).and_return(content_object)
    end

    it "contains 'Concept' as the first element" do
      expect(presenter.columns.first).to eq('Concept')
    end

    it 'contains the formative activity titles after the first element' do
      expect(presenter.columns.slice(1, formative_activity_titles.count))
        .to eq(formative_activity_titles)
    end

    it 'contains other required column titles after the formative activities' do
      other_required_column_titles = ['Score Change', 'Review', 'Practice']
      starting_index = formative_activity_titles.count + 2
      length = presenter.columns.count - formative_activity_titles.count + 1

      expect(presenter.columns.slice(starting_index, length))
        .to eq(other_required_column_titles)
    end
  end

  describe '#lesson' do
    it 'returns the lessons of the unit the activity is in, if in a unit program' do
      create(:lesson, unit: unit)
      expect(presenter.lesson).to match unit.lessons
    end

    it 'returns the lesson the activity is in, if in lesson program' do
      expect(presenter.lesson).to eq [lesson]
    end
  end

  describe '#summative_activity?' do
    context 'when there is a formative activity' do
      it 'returns true' do
        expect(presenter).to be_summative_activity
      end

      context 'when there are no formative activities' do
        let(:doc) do
          Nokogiri::XML.parse(diagnostic_v2_xml).tap do |doc|
            doc.search('//formative_activity').each(&:remove)
          end
        end

        it 'returns false' do
          expect(presenter).not_to be_summative_activity
        end
      end
    end
  end

  describe '#formative_activities' do
    it 'returns StudyPlan::FormativeActivity objects' do
      expect(presenter.formative_activities).not_to be_empty
      expect(presenter.formative_activities).to all be_a StudyPlan::FormativeActivity
    end

    it 'orders the activities by lesson and strand location' do
      same_lesson_different_strand_activity =
        create(:activity,
               lesson:,
               activity_type: 'diagnostic_v2',
               cms_activity_id: activity.cms_activity_id + 1,
               toc_location: lesson.strands.first.location)
      other_lesson = create(:lesson_with_toc_entries, unit:, rank: lesson.rank + 11)
      other_lesson_activity =
        create(:activity,
               lesson: other_lesson,
               activity_type: 'diagnostic_v2',
               cms_activity_id: activity.cms_activity_id + 2,
               toc_location: other_lesson.strands.first.location)
      formative_activity_element = doc.xpath('//formative_activity').first
      formative_activity_element.add_next_sibling(
        "<formative_activity id=\"#{same_lesson_different_strand_activity.cms_activity_id}\" title=\"Same Lesson Activity\"/>"
      )
      formative_activity_element.add_next_sibling(
        "<formative_activity id=\"#{other_lesson_activity.cms_activity_id}\" title=\"Other Lesson Activity\"/>"
      )
      allow(activity).to receive(:content_object).and_return(
        MaestroActivityEngine::ActivityParser.create_parser(doc.to_s, linked_media_item).parse
      )

      expect(presenter.formative_activities.map(&:id)).to eq(
        [same_lesson_different_strand_activity.id, activity.id, other_lesson_activity.id]
      )
    end

    context 'when the activity is not a diagnostic_v2 type' do
      it 'returns an empty array' do
        allow(activity).to receive(:activity_type).and_return('study_plan_practice_test')
        expect(presenter.formative_activities).to eq([])
      end
    end
  end
end
