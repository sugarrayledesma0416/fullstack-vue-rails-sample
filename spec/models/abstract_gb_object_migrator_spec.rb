describe AbstractGbObjectMigrator do
  # Using Course model to test the Abstract class
  let(:m3_course) { create(:course, name: 'M3 Course') }
  let(:add_update_params) do
    {
      action: 'add_update',
      id: m3_course.id,
      model_name: 'Course'
    }
  end
  let(:import_params) { add_update_params.merge(action: 'import') }

  describe 'add_update model action' do
    it 'creates a new gradebook course record if it does not exist' do
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_course = ::GradebookEngine::Course.find(m3_course.id)
      expect(new_gb_course.name).to eql(m3_course.name)
      expect(new_gb_course.school_id).to eq(m3_course.school_id)
    end

    it 'updates existing gradebook course record' do
      gb_course = ::GradebookEngine::Course.new()
      gb_course.name = 'Existing M3 Course'
      gb_course.id = m3_course.id
      gb_course.save
      gb_course = ::GradebookEngine::Course.find(m3_course.id)
      expect(gb_course.name).to eql('Existing M3 Course')
      m3_course.name = 'Modified M3 Course'
      m3_course.save
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      updated_gb_course = ::GradebookEngine::Course.find(m3_course.id)
      expect(updated_gb_course.name).to eql('Modified M3 Course')
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook course record' do
      gb_course = ::GradebookEngine::Course.new()
      gb_course.name = 'Existing M3 Course'
      gb_course.id = m3_course.id
      gb_course.save
      gb_course = ::GradebookEngine::Course.find(m3_course.id)
      expect(gb_course.name).to eql('Existing M3 Course')
      gb_migrator = described_class.new(m3_course.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil
      expect{::GradebookEngine::Course.find(m3_course.id)}.to raise_error(ActiveRecord::RecordNotFound)
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
      ::GradebookEngine::Course.create!(
        id: m3_course.id,
        name: 'Existing M3 Course'
      )
    end

    context 'with log level configured at :info,' do
      around do |example|
        run_with_temporary_log_level(example, :info)
      end

      it 'sends an error to logstash' do
        described_class.new(import_params).update_object

        expect(STATS_PROXY).to have_received(:relay).with(
          hash_including(
            message: /PG::UniqueViolation/,
            model: 'GradebookEngine::Course'
          )
        )
      end
    end

    context 'with log level configured at :error,' do
      around do |example|
        run_with_temporary_log_level(example, :error)
      end

      it 'sends an error to logstash' do
        described_class.new(import_params).update_object

        expect(STATS_PROXY).to have_received(:relay).with(
          hash_including(
            message: /PG::UniqueViolation/,
            model: 'GradebookEngine::Course'
          )
        )
      end
    end

    context 'with log level configured at :fatal,' do
      around do |example|
        run_with_temporary_log_level(example, :fatal)
      end

      it 'does not send an error to logstash' do
        described_class.new(import_params).update_object

        expect(STATS_PROXY).not_to have_received(:relay)
      end
    end
  end
end
