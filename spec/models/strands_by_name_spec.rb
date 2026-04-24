class StrandsByNameTester
  include StrandsByName

  attr_reader :lessons_covered

  def initialize(lessons)
    @lessons_covered = lessons
  end
end

describe StrandsByNameTester do

  describe "#strand_ids_by_name" do
    let(:unit_1) { create(:unit_with_lesson_with_toc_entries, name: 'lesson 1') }
    let(:unit_2) { create(:unit_with_lesson_with_toc_entries, name: 'lesson 2') }
    let(:unit_3) { create(:unit_with_lesson_with_toc_entries, name: 'lesson 3') }
    let(:strand_1) { create(:toc_entry, title: 'strand 1', location: 1) }
    let(:strand_2_1) { create(:toc_entry, title: 'strand 2', short_title: 'st2', location: 21) }
    let(:substrand_2_1) { create(:toc_entry, title: 'substrand 1', location: 210, level: 2) }
    let(:strand_2_2) { create(:toc_entry, title: 'strand 2', short_title: 'st2', location: 22) }
    let(:substrand_2_2) { create(:toc_entry, title: 'substrand 2', location: 220, level: 2) }
    let(:strand_3) { create(:toc_entry, title: 'strand 3', location: 3) }
    let(:strand_4) { create(:toc_entry, title: 'strand 4', location: 4) }
    let(:lesson_1) { unit_1.lessons.first }
    let(:lesson_2) { unit_2.lessons.first }
    let(:lesson_3) { unit_3.lessons.first }
    let(:lessons) { [lesson_1, lesson_2, lesson_3] }
    let(:tester) { described_class.new(lessons) }


    before(:each) do
      lesson_1.toc_entries << strand_1
      lesson_1.toc_entries << strand_2_1
      lesson_2.toc_entries << strand_2_2
      lesson_2.toc_entries << strand_3
      allow(strand_2_1).to receive(:children) { [substrand_2_1] }
      allow(strand_2_2).to receive(:children) { [substrand_2_2] }
      lesson_1.save!
      lesson_2.save!
      lesson_3.save!
    end

    it "returns an array of toc_locations" do
      expect(tester.strand_ids_by_name('strand 2')).to eq  [21, 22]
    end

    it "returns an array of locations based on the short strand name" do
      expect(tester.strand_ids_by_name('st2')).to eq  [21, 22]
    end

    it "returns substrands when include_substrands is true" do
      expect(tester.strand_ids_by_name('strand 2', true)).to eq  [21, 22, 210, 220]
    end
  end
end
