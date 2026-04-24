describe Etl::GradebookImport::Activity do
  let(:lesson_1) { create(:gb_lesson) }
  let(:lesson_2) { create(:gb_lesson) }
  let(:strand_1) { create(:gb_strand) }
  let(:strand_2) { create(:gb_strand) }
  let(:new_attrs) do
    {
      'activity_type' => 'tutorial_vocab_html5',
      'cdn' => true,
      'cms_activity_id' => 209,
      'cms_revision_id' => 603,
      'component_name' => 'Presentations and Tutorials',
      'concept_id' => strand_1.id,
      'concept_rank' => 20,
      'content_summary' => {},
      'created_at' => '2012-09-19T04:45:57-04:00',
      'grading_method' => 'auto',
      'hide_from_my_content' => false,
      'icon' => '',
      'id' => 27,
      'instructor_id' => nil,
      'instructor_revision_id' => nil,
      'lesson_id' => lesson_1.id,
      'license_group_id' => 1,
      'max_attempts' => 0,
      'minutes_to_complete' => 3,
      'page' => '2-5',
      'points_possible' => 1,
      'singular_label' => 'activity',
      'submittable' => false,
      'thumbnail_path' => nil,
      'title' => '<b>Tutorial</b>: Los saludos y las despedidos',
      'student_title' => 'Tutorial: Los saludos y las despedidos student',
      'toc_location' => strand_1.id,
      'toc_location_rank' => 10,
      'updated_at' => '2016-07-01T09:24:17-04:00'
    }
  end

  let(:update_attrs) do
    new_attrs.merge(
      'concept_id' => strand_2.id,
      'concept_rank' => 30,
      'grading_method' => 'instructor',
      'lesson_id' => lesson_2.id,
      'submittable' => true,
      'title' => '<b>Tutorial</b>: Los saludos y las despedidas',
      'student_title' => 'Tutorial: Los saludos y las despedidos student'
    )
  end

  describe 'import model action' do
    it 'creates a new gradebook activity record when action is import' do
      gb_import_model = described_class.new(
        GradebookEngine::Activity, 'import', new_attrs
      )
      new_activity = gb_import_model.get_or_delete_record
      expect(new_activity.id).to eq(27)
      expect(new_activity.lesson_id).to eql(lesson_1.id)
      expect(new_activity.strand_id).to eql(strand_1.id)
      expect(new_activity.student_title).to eql('Tutorial: Los saludos y las despedidos student')
    end

    it 'throws uniqueness error saving new activity with existing M3 id' do
      gb_import_model = described_class.new(
        GradebookEngine::Activity, 'import', new_attrs
      )
      new_activity = gb_import_model.get_or_delete_record
      new_activity.save!
      another_new_activity = gb_import_model.get_or_delete_record
      expect { another_new_activity.save }.to raise_error(
        ActiveRecord::RecordNotUnique
      )
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook activity if it does not exist' do
      gb_import_model = described_class.new(
        GradebookEngine::Activity, 'add_update', new_attrs
      )
      new_activity = gb_import_model.get_or_delete_record
      expect(new_activity.id).to eq(27)
    end

    it 'updates existing gradebook activity' do
      gb_import_model = described_class.new(
        GradebookEngine::Activity, 'add_update', new_attrs
      )
      new_activity = gb_import_model.get_or_delete_record
      new_activity.save!
      new_activity = ::GradebookEngine::Activity.find(27)
      expect(new_activity.name).to eql('Tutorial: Los saludos y las despedidos')
      expect(new_activity.grading_method).to eql('auto')
      expect(new_activity.rank).to eq 20
      expect(new_activity.gradeable).to be_falsey
      expect(new_activity.lesson_id).to eql(lesson_1.id)
      expect(new_activity.strand_id).to eql(strand_1.id)
      expect(new_activity.student_title).to eql('Tutorial: Los saludos y las despedidos student')
      gb_import_model = described_class.new(
        GradebookEngine::Activity, 'add_update', update_attrs
      )
      updated_activity = gb_import_model.get_or_delete_record
      updated_activity.save!
      updated_activity = ::GradebookEngine::Activity.find(27)
      expect(updated_activity.name).to eql('Tutorial: Los saludos y las despedidas')
      expect(updated_activity.grading_method).to eql('instructor')
      expect(updated_activity.rank).to eq 30
      expect(updated_activity.gradeable).to be_truthy
      expect(updated_activity.lesson_id).to eql(lesson_2.id)
      expect(updated_activity.strand_id).to eql(strand_2.id)
    end
  end
end
