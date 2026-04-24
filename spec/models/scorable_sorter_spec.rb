describe ScorableSorter do
  describe '#toc_location_rank_in_lesson' do
    let(:lesson) { create(:lesson) }
    context 'when used extending activities' do
      it "calls toc_location_rank_by_id on the activity's lesson" do
        activity = create(:activity, lesson: lesson)
        expect(lesson).to receive(:toc_location_rank_by_id).with(activity.toc_location)
        activity.toc_location_rank_in_lesson
      end
    end
  end

  describe '#sort_by_location' do
    let(:section) { build_stubbed(:section) }
    let(:lesson_1) { create(:lesson, toc_entries_xml: Nokogiri::XML(File.open('spec/fixtures/xml/lesson.xml') ).to_xml,
                                        unit: create(:unit, rank: 10), rank: 10) }
    let(:lesson_2) { create(:lesson, toc_entries_xml: Nokogiri::XML(File.open('spec/fixtures/xml/lesson.xml') ).to_xml,
                                        unit:create(:unit, rank: 20), rank: 20) }
    let(:lesson_1_substrand_1_id) { 214600000 }
    let(:lesson_1_substrand_2_id) { 214800000 }

    let(:lesson_2_substrand_3_id) { 215201523 }
    let(:lesson_2_substrand_4_id) { 215201524 }

    let(:lesson_1_substrand_1_activity_1) { create(:activity, lesson: lesson_1, title: 'AA', toc_location: lesson_1_substrand_1_id,
                                                       concept_rank: 10) }
    let(:lesson_1_substrand_1_activity_2) { create(:activity, lesson: lesson_1, title: 'AA', toc_location: lesson_1_substrand_1_id,
                                                       concept_rank: 20) }
    let(:lesson_1_substrand_2_activity) { create(:activity, lesson: lesson_1, title: 'DD', toc_location: lesson_1_substrand_2_id,
                                                       concept_rank: 30) }

    let(:lesson_2_substrand_3_activity) { create(:activity, lesson: lesson_2, title: 'AA', toc_location: lesson_2_substrand_3_id,
                                                       concept_rank: 10) }
    let(:lesson_2_substrand_4_activity) { create(:activity, lesson: lesson_2, title: 'DD', toc_location: lesson_2_substrand_4_id,
                                                       concept_rank: 20) }

    class SortByLocationTestClass
      include ScorableSorter
    end

    context 'when sorting activities' do
      it 'sorts passed activities by lesson' do
        activities = [lesson_2_substrand_3_activity, lesson_1_substrand_2_activity]
        expect(SortByLocationTestClass.new.sort_by_location(activities)).to eq([lesson_1_substrand_2_activity, lesson_2_substrand_3_activity])
      end

      # it 'sorts passed activities by toc location' do
      #   activities = [lesson_1_substrand_2_activity, lesson_1_substrand_1_activity_1]
      #   SortByLocationTestClass.new.sort_by_location(activities).should == [lesson_1_substrand_1_activity_1, lesson_1_substrand_2_activity]
      # end

      it 'sorts passed activities by concept rank' do
        activities = [lesson_1_substrand_1_activity_2, lesson_1_substrand_1_activity_1]
        expect(SortByLocationTestClass.new.sort_by_location(activities)).to eq([lesson_1_substrand_1_activity_1, lesson_1_substrand_1_activity_2])
      end

      it 'sorts passed activities by lesson and concept rank' do
        activities = [lesson_2_substrand_4_activity,
                      lesson_1_substrand_2_activity,
                      lesson_1_substrand_1_activity_2,
                      lesson_2_substrand_3_activity,
                      lesson_1_substrand_1_activity_1]
        sorted_activities = [lesson_1_substrand_1_activity_1,
                             lesson_1_substrand_1_activity_2,
                             lesson_1_substrand_2_activity,
                             lesson_2_substrand_3_activity,
                             lesson_2_substrand_4_activity]
        expect(SortByLocationTestClass.new.sort_by_location(activities)).to eq(sorted_activities)
      end
    end

    context 'when sorting assignments' do
      let(:today) { Date.today }
      let(:lesson_1_substrand_1_assignment_1) { create(:assignment, section: section, due_date: today, assignable: lesson_1_substrand_1_activity_1) }
      let(:lesson_1_substrand_1_assignment_2) { create(:assignment, section: section, due_date: today, assignable: lesson_1_substrand_1_activity_2) }
      let(:lesson_1_substrand_2_assignment)   { create(:assignment, section: section, due_date: today, assignable: lesson_1_substrand_2_activity) }
      let(:lesson_2_substrand_3_assignment)   { create(:assignment, section: section, due_date: today, assignable: lesson_2_substrand_3_activity) }
      let(:lesson_2_substrand_4_assignment)   { create(:assignment, section: section, due_date: today, assignable: lesson_2_substrand_4_activity) }

      it 'sorts passed assignments by lesson' do
        assignments = [lesson_2_substrand_3_assignment, lesson_1_substrand_2_assignment]
        expect(SortByLocationTestClass.new.sort_by_location(assignments)).to eq([lesson_1_substrand_2_assignment, lesson_2_substrand_3_assignment])
      end

      # it 'sorts passed assignments by toc location' do
      #   assignments = [lesson_1_substrand_2_assignment, lesson_1_substrand_1_assignment_1]
      #   SortByLocationTestClass.new.sort_by_location(assignments).should == [lesson_1_substrand_1_assignment_1, lesson_1_substrand_2_assignment]
      # end

      it 'sorts passed assignments by concept rank' do
        assignments = [lesson_1_substrand_1_assignment_2, lesson_1_substrand_1_assignment_1]
        expect(SortByLocationTestClass.new.sort_by_location(assignments)).to eq([lesson_1_substrand_1_assignment_1, lesson_1_substrand_1_assignment_2])
      end

      it 'sorts passed assignments by lesson, toc location and concept rank' do
        assignments = [lesson_2_substrand_4_assignment,
                      lesson_1_substrand_2_assignment,
                      lesson_1_substrand_1_assignment_2,
                      lesson_2_substrand_3_assignment,
                      lesson_1_substrand_1_assignment_1]
        sorted_assignments = [lesson_1_substrand_1_assignment_1,
                             lesson_1_substrand_1_assignment_2,
                             lesson_1_substrand_2_assignment,
                             lesson_2_substrand_3_assignment,
                             lesson_2_substrand_4_assignment]
        expect(SortByLocationTestClass.new.sort_by_location(assignments)).to eq(sorted_assignments)
      end
    end
  end

  describe '#location_value' do
    let(:strand) { create(:toc_entry) }
    let(:lesson) { create(:lesson, :toc_entries => [strand], unit: create(:unit)) }

    before do
      allow(lesson).to receive(:program).and_return(build_stubbed(:program))
      lesson.concepts << create(:concept_with_calculated_combined_rank, lesson: lesson)
    end

    context 'when called from an activity' do
      it "returns the product of the activity's lesson_combined_rank, toc_location_rank_in_lesson, concept_rank" do
        activity = create(:activity, :lesson => lesson, :toc_location => strand.location)
        expected_location_value = 10**3 * activity.concept_combined_rank + activity.concept_rank
        expect(activity.location_value).to eq(expected_location_value)
      end
    end
  end
end
