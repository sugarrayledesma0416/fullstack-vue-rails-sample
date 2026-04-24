describe Etl::GradebookImport::Strand do
  let(:new_attrs) do
    {
      'assessment' => false,
      'background_color' => '#0066B3',
      'base_name' => 'Strukturen',
      'breadcrumb_string' => '<b>Strukturen 5.1</b> <br />Modals',
      'id' => 13,
      'lesson_combined_rank' => 601,
      'lesson_id' => 526,
      'name' => '<b>Strukturen 6A.2</b> <br /><i>Da-, wo-, hin-</i>, and <i>her-</i>compounds',
      'program_id' => 93,
      'rank' => 4,
      'singular_label' => nil
    }
  end

  let(:update_attrs) do
    new_attrs.merge('assessment' => false,
                    'name' => 'Structure',
                    'rank' => 2,
                    'background_color' => '#DA9A22')
  end

  describe 'import model action' do
    it 'creates a new gradebook strand record when action is import' do
      gb_import_model = described_class.new(GradebookEngine::Strand,
                                            'import',
                                            new_attrs)
      new_strand = gb_import_model.get_or_delete_record
      expect(new_strand.assessment).to be_falsey
      expect(new_strand.id).to eql(13)
    end

    it 'throws uniqueness error saving new strand with existing M3 id' do
      gb_import_model = described_class.new(GradebookEngine::Strand,
                                            'import',
                                            new_attrs)
      new_strand = gb_import_model.get_or_delete_record
      new_strand.save
      another_new_strand = gb_import_model.get_or_delete_record
      expect { another_new_strand.save }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook strand record if it does not exist' do
      gb_import_model = described_class.new(GradebookEngine::Strand,
                                            'add_update',
                                            new_attrs)
      new_strand = gb_import_model.get_or_delete_record
      expect(new_strand.id).to eql(13)
    end

    it 'updates existing gradebook strand record' do
      gb_import_model = described_class.new(GradebookEngine::Strand,
                                            'add_update',
                                            new_attrs)
      new_strand = gb_import_model.get_or_delete_record
      new_strand.save
      new_strand = ::GradebookEngine::Strand.find(13)
      expect(new_strand.assessment).to be_falsey
      expect(new_strand.name).to eql('Strukturen 6A.2  Da-, wo-, hin-, and her-compounds')
      expect(new_strand.color).to eql('#0066B3')
      expect(new_strand.rank).to eq 5
      gb_import_model = described_class.new(GradebookEngine::Strand,
                                            'add_update',
                                            update_attrs)
      updated_strand = gb_import_model.get_or_delete_record
      updated_strand.save
      updated_strand = ::GradebookEngine::Strand.find(13)
      expect(updated_strand.name).to eql('Structure')
      expect(updated_strand.color).to eql('#DA9A22')
      expect(updated_strand.rank).to eq 3
    end
  end
end
