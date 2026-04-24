describe Etl::GradebookImport::Base do
  let(:new_attrs) do
    {
      'allow_video_popup_translation' => false,
      'allows_help_requests' => false,
      'allows_review_requests' => false,
      'chat_level' => 'partner_chat',
      'components' => nil,
      'course_package_ids' => nil,
      'created_at' => '2012-05-31T19:12:33-04:00',
      'current_events_unit_id' => 9,
      'draft' => false,
      'end_date' => '2012-09-06',
      'first_unit_id' => 1,
      'guid' => '101',
      'id' => 101,
      'is_archived' => false,
      'is_demo' => false,
      'last_unit_id' => 15,
      'level' => nil,
      'name' => 'MDE Pano4 course',
      'owner_id' => 838,
      'program_id' => 48,
      'request_id' => nil,
      'school_id' => 448,
      'show_estimated_times' => true,
      'start_date' => '2012-05-31',
      'sync_token' => 0,
      'updated_at' => '2012-05-31T19:12:33-04:00',
      'allow_audio_transcripts' => false,
      'video_subtitle_languages' => 'foreign',
      'video_transcript_languages' => '0'
    }
  end

  let(:update_attrs) { new_attrs.merge('end_date' => '2012-10-06', 'start_date' => '2012-06-01', 'last_unit_id' => 12) }

  describe 'import model action' do
    it 'creates a new gradebook course record when action is import' do
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'import', new_attrs)
      new_course = gb_import_model.get_or_delete_record
      expect(new_course.id).to eql(101)
    end

    it 'throws uniqueness error saving new gradebook course record with existing M3 id' do
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'import', new_attrs)
      new_course = gb_import_model.get_or_delete_record
      new_course.save
      another_new_course = gb_import_model.get_or_delete_record
      expect { another_new_course.save }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook course record if it does not exist' do
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'add_update', new_attrs)
      new_course = gb_import_model.get_or_delete_record
      expect(new_course.id).to eql(101)
    end

    it 'updates existing gradebook course record' do
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'add_update', new_attrs)
      new_course = gb_import_model.get_or_delete_record
      new_course.save
      new_course = ::GradebookEngine::Course.find(101)
      initial_start_date = new_course.start_date.to_formatted_s
      initial_end_date = new_course.end_date.to_formatted_s
      expect(initial_start_date).to eql('2012-05-31')
      expect(initial_end_date).to eql('2012-09-06')
      expect(new_course.first_unit_id).to eql(1)
      expect(new_course.last_unit_id).to eql(15)
      expect(new_course.current_events_unit_id).to eq(9)
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'add_update', update_attrs)
      updated_course = gb_import_model.get_or_delete_record
      updated_course.save
      updated_course = ::GradebookEngine::Course.find(101)
      modified_start_date = updated_course.start_date.to_formatted_s
      modified_end_date = updated_course.end_date.to_formatted_s
      expect(modified_start_date).to eql('2012-06-01')
      expect(modified_end_date).to eql('2012-10-06')
      expect(updated_course.last_unit_id).to eql(12)
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook course record' do
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'import', new_attrs)
      new_course1 = gb_import_model.get_or_delete_record
      new_course1.save
      another_course_attrs = new_attrs.merge('id' => 107)
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'import', another_course_attrs)
      new_course2 = gb_import_model.get_or_delete_record
      new_course2.save
      another_course_attrs = new_attrs.merge('id' => 108)
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'import', another_course_attrs)
      new_course3 = gb_import_model.get_or_delete_record
      new_course3.save
      expect(::GradebookEngine::Course.all.count).to eq 3
      delete_attrs = new_attrs.merge('id' => 107)
      gb_import_model = Etl::GradebookImport::Course.new(GradebookEngine::Course, 'delete', delete_attrs)
      deleted_course = gb_import_model.get_or_delete_record
      expect(deleted_course).to be_nil
      expect(::GradebookEngine::Course.all.count).to eq 2
    end
  end

  describe 'logstash logging' do
    def run_with_temporary_log_level(example, temp_level)
      old_level = Rails.configuration.etl_log_level
      Rails.configuration.etl_log_level = temp_level
      example.run
      Rails.configuration.etl_log_level = old_level
    end

    before do
      allow(STATS_PROXY).to receive(:relay)
    end

    context 'with log level configured at :info,' do
      around do |example|
        run_with_temporary_log_level(example, :info)
      end

      it 'sends data to logstash' do
        Etl::GradebookImport::Course.new(
          GradebookEngine::Course,
          'delete',
          new_attrs.merge('id' => 17)
        ).get_or_delete_record

        expect(STATS_PROXY).to have_received(:relay).with(
          hash_including(message: '{:id=>17}', model: 'GradebookEngine::Course')
        )
      end
    end

    context 'with log level configured at :error,' do
      around do |example|
        run_with_temporary_log_level(example, :error)
      end

      it 'does not send data to logstash' do
        Etl::GradebookImport::Course.new(
          GradebookEngine::Course,
          'delete',
          new_attrs.merge('id' => 17)
        ).get_or_delete_record

        expect(STATS_PROXY).not_to have_received(:relay)
      end
    end
  end
end
