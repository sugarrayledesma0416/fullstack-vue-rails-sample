describe CopyExternalItemsWorker do
  let(:source_category) { create(:category, name: 'Homework') }
  let(:destination_category) { create(:category, name: 'Projects', course: source_category.course) }
  let(:destination_section) { create(:section, course: destination_category.course) }
  let(:source_section) { create(:section) }
  let(:categories_hash) do
    {
      'Homework' => { 'id' => destination_category.id, 'name' => destination_category.name }
    }
  end

  before do
    allow(GradebookEngine::GradebookAPI).to receive(:copy_external_assignments)
  end

  describe 'when use_course_categories_map is true' do
    it 'calls GradebookEngine::GradebookAPI#copy_external_assignments with categories_hash' do
      described_class.new.perform(destination_section.id, source_section.id, true, categories_hash)

      expect(GradebookEngine::GradebookAPI).to have_received(:copy_external_assignments)
        .with(source_section.id, destination_section.id, categories_hash)
    end
  end

  describe 'when use_course_categories_map is false' do
    it 'calls GradebookEngine::GradebookAPI#copy_external_assignments without categories_hash' do
      described_class.new.perform(destination_section.id, source_section.id, false, nil)

      expect(GradebookEngine::GradebookAPI).to have_received(:copy_external_assignments)
        .with(source_section.id, destination_section.id, nil)
    end
  end

  describe 'when destination section is an enterprise section' do
    it 'processes all associated sections and uses the correct categories_hash' do
      enterprise_course = create(:enterprise_course)
      enterprise_section = create(:enterprise_section, course: enterprise_course)
      associated_section = create(:section, source_template_id: enterprise_section.id)

      described_class.new.perform(enterprise_section.id, source_section.id, true, categories_hash)

      expect(GradebookEngine::GradebookAPI).to have_received(:copy_external_assignments)
        .with(source_section.id, enterprise_section.id, categories_hash).once

      expect(GradebookEngine::GradebookAPI).to have_received(:copy_external_assignments)
        .with(source_section.id, associated_section.id, categories_hash).once
    end
  end
end
