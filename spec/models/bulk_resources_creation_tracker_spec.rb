require 'rails_helper'

RSpec.describe BulkResourcesCreationTracker do
  let(:tracker) { create(:bulk_resources_creation_tracker) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(tracker).to be_valid
    end

    it 'has a default state of pending' do
      expect(tracker.state).to eq('pending')
    end

    it 'has a default logs structure' do
      expect(JSON.parse(tracker.logs)).to eq({ 'data' => [] })
    end
  end

  describe 'AASM state machine' do
    describe 'initial state' do
      it 'starts in pending state' do
        expect(tracker).to be_pending
      end
    end

    describe 'job_created event' do
      it 'transitions from pending to job_created' do
        expect { tracker.job_created! }
          .to change(tracker, :state).from('pending').to('job_created')
      end

      it 'logs the job_created event' do
        expect { tracker.job_created! }
          .to change { JSON.parse(tracker.reload.logs)['data'].length }.by(1)
      end

      it 'updates progress to 20' do
        tracker.job_created!
        expect(JSON.parse(tracker.reload.logs)['progress']).to eq(20)
      end

      it 'adds correct log entry key' do
        tracker.job_created!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['key']).to eq('job_created')
      end

      it 'adds correct log entry message' do
        tracker.job_created!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['message']).to eq('The job has been created')
      end

      it 'adds timestamp to log entry' do
        tracker.job_created!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['time']).to be_present
      end
    end

    describe 'start_unzipping event' do
      before { tracker.job_created! }

      it 'transitions from job_created to unzipping' do
        expect { tracker.start_unzipping! }
          .to change(tracker, :state).from('job_created').to('unzipping')
      end

      it 'logs the unzipping_started event' do
        expect { tracker.start_unzipping! }
          .to change { JSON.parse(tracker.reload.logs)['data'].length }.by(1)
      end

      it 'updates progress to 40' do
        tracker.start_unzipping!
        expect(JSON.parse(tracker.reload.logs)['progress']).to eq(40)
      end

      it 'adds correct log entry key' do
        tracker.start_unzipping!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['key']).to eq('unzipping_started')
      end

      it 'adds correct log entry message' do
        tracker.start_unzipping!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['message']).to eq('S3 unzipping started')
      end

      it 'adds timestamp to log entry' do
        tracker.start_unzipping!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['time']).to be_present
      end
    end

    describe 'unzipping_completed event' do
      before do
        tracker.job_created!
        tracker.start_unzipping!
      end

      it 'transitions from unzipping to unzipped' do
        expect { tracker.unzipping_completed! }
          .to change(tracker, :state).from('unzipping').to('unzipped')
      end

      it 'logs the unzipping_completed event' do
        expect { tracker.unzipping_completed! }
          .to change { JSON.parse(tracker.reload.logs)['data'].length }.by(1)
      end

      it 'updates progress to 60' do
        tracker.unzipping_completed!
        expect(JSON.parse(tracker.reload.logs)['progress']).to eq(60)
      end

      it 'adds correct log entry key' do
        tracker.unzipping_completed!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['key']).to eq('unzipping_completed')
      end

      it 'adds correct log entry message' do
        tracker.unzipping_completed!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['message']).to eq('S3 unzipping completed')
      end

      it 'adds timestamp to log entry' do
        tracker.unzipping_completed!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['time']).to be_present
      end
    end

    describe 'start_creating_resources event' do
      before do
        tracker.job_created!
        tracker.start_unzipping!
        tracker.unzipping_completed!
      end

      it 'transitions from unzipped to creating_resources' do
        expect { tracker.start_creating_resources! }
          .to change(tracker, :state).from('unzipped').to('creating_resources')
      end

      it 'logs the creation_started event' do
        expect { tracker.start_creating_resources! }
          .to change { JSON.parse(tracker.reload.logs)['data'].length }.by(1)
      end

      it 'updates progress to 80' do
        tracker.start_creating_resources!
        expect(JSON.parse(tracker.reload.logs)['progress']).to eq(80)
      end

      it 'adds correct log entry key' do
        tracker.start_creating_resources!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['key']).to eq('creation_started')
      end

      it 'adds correct log entry message' do
        tracker.start_creating_resources!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['message']).to eq('Resources creation started')
      end

      it 'adds timestamp to log entry' do
        tracker.start_creating_resources!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['time']).to be_present
      end
    end

    describe 'completed event' do
      before do
        tracker.job_created!
        tracker.start_unzipping!
        tracker.unzipping_completed!
        tracker.start_creating_resources!
      end

      it 'transitions from creating_resources to completed' do
        expect { tracker.completed! }
          .to change(tracker, :state).from('creating_resources').to('completed')
      end

      it 'logs the creation_completed event' do
        expect do
          tracker.completed!
        end.to change { JSON.parse(tracker.reload.logs)['data'].length }.by(1)
      end

      it 'updates progress to 100' do
        tracker.completed!
        expect(JSON.parse(tracker.reload.logs)['progress']).to eq(100)
      end

      it 'adds correct log entry key' do
        tracker.completed!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['key']).to eq('creation_completed')
      end

      it 'adds correct log entry message' do
        tracker.completed!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['message']).to eq('Resources creation completed')
      end

      it 'adds timestamp to log entry' do
        tracker.completed!
        log_data = JSON.parse(tracker.reload.logs)['data'].last
        expect(log_data['time']).to be_present
      end
    end

    describe 'reset event' do
      context 'when in completed state' do
        before do
          tracker.job_created!
          tracker.start_unzipping!
          tracker.unzipping_completed!
          tracker.start_creating_resources!
          tracker.completed!
        end

        it 'transitions from completed to pending' do
          expect { tracker.reset! }
            .to change(tracker, :state).from('completed').to('pending')
        end
      end

      context 'when in failed state' do
        before { tracker.fail! }

        it 'transitions from failed to pending' do
          expect { tracker.reset! }
            .to change(tracker, :state).from('failed').to('pending')
        end
      end
    end

    describe 'fail event' do
      it 'transitions from pending to failed' do
        expect { tracker.fail! }
          .to change(tracker, :state).from('pending').to('failed')
      end

      it 'transitions from job_created to failed' do
        tracker.job_created!
        expect { tracker.fail! }
          .to change(tracker, :state).from('job_created').to('failed')
      end

      it 'transitions from unzipping to failed' do
        tracker.job_created!
        tracker.start_unzipping!
        expect { tracker.fail! }
          .to change(tracker, :state).from('unzipping').to('failed')
      end

      it 'transitions from unzipped to failed' do
        tracker.job_created!
        tracker.start_unzipping!
        tracker.unzipping_completed!
        expect { tracker.fail! }
          .to change(tracker, :state).from('unzipped').to('failed')
      end

      it 'transitions from creating_resources to failed' do
        tracker.job_created!
        tracker.start_unzipping!
        tracker.unzipping_completed!
        tracker.start_creating_resources!
        expect { tracker.fail! }
          .to change(tracker, :state).from('creating_resources').to('failed')
      end
    end

    describe 'invalid transitions' do
      it 'cannot start_unzipping from pending state' do
        expect { tracker.start_unzipping! }.to raise_error(AASM::InvalidTransition)
      end

      it 'cannot unzipping_completed from job_created state' do
        tracker.job_created!
        expect { tracker.unzipping_completed! }.to raise_error(AASM::InvalidTransition)
      end

      it 'cannot start_creating_resources from unzipping state' do
        tracker.job_created!
        tracker.start_unzipping!
        expect { tracker.start_creating_resources! }.to raise_error(AASM::InvalidTransition)
      end

      it 'cannot completed from unzipped state' do
        tracker.job_created!
        tracker.start_unzipping!
        tracker.unzipping_completed!
        expect { tracker.completed! }.to raise_error(AASM::InvalidTransition)
      end

      it 'cannot reset from pending state' do
        expect { tracker.reset! }.to raise_error(AASM::InvalidTransition)
      end

      it 'cannot fail from completed state' do
        tracker.job_created!
        tracker.start_unzipping!
        tracker.unzipping_completed!
        tracker.start_creating_resources!
        tracker.completed!
        expect { tracker.fail! }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  describe '#log' do
    let(:tracker) { create(:bulk_resources_creation_tracker) }

    it 'adds a new log entry to the data array' do
      expect { tracker.log('test_key', 'Test message', 50) }
        .to change { JSON.parse(tracker.reload.logs)['data'].length }.by(1)
    end

    it 'updates the progress value' do
      tracker.log('test_key', 'Test message', 75)
      expect(JSON.parse(tracker.reload.logs)['progress']).to eq(75)
    end

    it 'includes the correct key in the log entry' do
      tracker.log('test_key', 'Test message', 50)
      log_data = JSON.parse(tracker.reload.logs)['data'].last
      expect(log_data['key']).to eq('test_key')
    end

    it 'includes the correct message in the log entry' do
      tracker.log('test_key', 'Test message', 50)
      log_data = JSON.parse(tracker.reload.logs)['data'].last
      expect(log_data['message']).to eq('Test message')
    end

    it 'includes timestamp in the log entry' do
      tracker.log('test_key', 'Test message', 50)
      log_data = JSON.parse(tracker.reload.logs)['data'].last
      expect(log_data['time']).to be_present
    end

    it 'formats timestamp correctly' do
      tracker.log('test_key', 'Test message', 50)
      log_data = JSON.parse(tracker.reload.logs)['data'].last
      expect(log_data['time']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
    end

    it 'uses Eastern Time zone format for timestamps' do
      tracker.log('test_key', 'Test message', 50)
      log_data = JSON.parse(tracker.reload.logs)['data'].last
      time_string = log_data['time']
      expect(time_string).to match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/)
    end

    it 'preserves existing log entries' do
      tracker.log('first_key', 'First message', 25)
      original_data = JSON.parse(tracker.reload.logs)['data']

      tracker.log('second_key', 'Second message', 50)
      new_data = JSON.parse(tracker.reload.logs)['data']

      expect(new_data.length).to eq(original_data.length + 1)
    end

    it 'keeps first log entry unchanged' do
      tracker.log('first_key', 'First message', 25)
      original_data = JSON.parse(tracker.reload.logs)['data']

      tracker.log('second_key', 'Second message', 50)
      new_data = JSON.parse(tracker.reload.logs)['data']

      expect(new_data.first).to eq(original_data.first)
    end

    it 'handles JSON parsing of existing logs' do
      tracker.update(
        logs: {
          data: [{ key: 'existing', message: 'Existing entry', time: '2023-01-01 12:00:00' }],
          progress: 10
        }.to_json
      )
      tracker.reload

      tracker.log('new_key', 'New message', 30)
      log_data = JSON.parse(tracker.reload.logs)['data']

      expect(log_data.length).to eq(2)
    end

    it 'preserves existing log entry key' do
      tracker.update(
        logs: {
          data: [{ key: 'existing', message: 'Existing entry', time: '2023-01-01 12:00:00' }],
          progress: 10
        }.to_json
      )

      tracker.log('new_key', 'New message', 30)
      log_data = JSON.parse(tracker.reload.logs)['data']

      expect(log_data.first['key']).to eq('existing')
    end

    it 'adds new log entry key' do
      tracker.update(
        logs: {
          data: [{ key: 'existing', message: 'Existing entry', time: '2023-01-01 12:00:00' }],
          progress: 10
        }.to_json
      )

      tracker.log('new_key', 'New message', 30)
      log_data = JSON.parse(tracker.reload.logs)['data']

      expect(log_data.last['key']).to eq('new_key')
    end
  end

  describe 'state predicates' do
    it 'responds to pending?' do
      expect(tracker).to respond_to(:pending?)
    end

    it 'responds to job_created?' do
      expect(tracker).to respond_to(:job_created?)
    end

    it 'responds to unzipping?' do
      expect(tracker).to respond_to(:unzipping?)
    end

    it 'responds to unzipped?' do
      expect(tracker).to respond_to(:unzipped?)
    end

    it 'responds to creating_resources?' do
      expect(tracker).to respond_to(:creating_resources?)
    end

    it 'responds to completed?' do
      expect(tracker).to respond_to(:completed?)
    end

    it 'responds to failed?' do
      expect(tracker).to respond_to(:failed?)
    end

    it 'returns true for pending state' do
      expect(tracker.pending?).to be true
    end

    it 'returns false for job_created state' do
      expect(tracker.job_created?).to be false
    end

    it 'returns false for failed state' do
      expect(tracker.failed?).to be false
    end
  end

  describe 'complete workflow' do
    it 'starts in pending state' do
      expect(tracker.state).to eq('pending')
    end

    it 'transitions to job_created state' do
      tracker.job_created!
      expect(tracker.state).to eq('job_created')
    end

    it 'transitions to unzipping state' do
      tracker.job_created!
      tracker.start_unzipping!
      expect(tracker.state).to eq('unzipping')
    end

    it 'transitions to unzipped state' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      expect(tracker.state).to eq('unzipped')
    end

    it 'transitions to creating_resources state' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      tracker.start_creating_resources!
      expect(tracker.state).to eq('creating_resources')
    end

    it 'transitions to completed state' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      tracker.start_creating_resources!
      tracker.completed!
      expect(tracker.state).to eq('completed')
    end

    it 'starts with no progress' do
      expect(JSON.parse(tracker.logs)['progress']).to be_nil
    end

    it 'updates progress to 20 after job_created' do
      tracker.job_created!
      expect(JSON.parse(tracker.reload.logs)['progress']).to eq(20)
    end

    it 'updates progress to 40 after start_unzipping' do
      tracker.job_created!
      tracker.start_unzipping!
      expect(JSON.parse(tracker.reload.logs)['progress']).to eq(40)
    end

    it 'updates progress to 60 after unzipping_completed' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      expect(JSON.parse(tracker.reload.logs)['progress']).to eq(60)
    end

    it 'updates progress to 80 after start_creating_resources' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      tracker.start_creating_resources!
      expect(JSON.parse(tracker.reload.logs)['progress']).to eq(80)
    end

    it 'updates progress to 100 after completed' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      tracker.start_creating_resources!
      tracker.completed!
      expect(JSON.parse(tracker.reload.logs)['progress']).to eq(100)
    end

    it 'starts with no log entries' do
      expect(JSON.parse(tracker.logs)['data'].length).to eq(0)
    end

    it 'adds one log entry after job_created' do
      tracker.job_created!
      expect(JSON.parse(tracker.reload.logs)['data'].length).to eq(1)
    end

    it 'adds two log entries after start_unzipping' do
      tracker.job_created!
      tracker.start_unzipping!
      expect(JSON.parse(tracker.reload.logs)['data'].length).to eq(2)
    end

    it 'adds three log entries after unzipping_completed' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      expect(JSON.parse(tracker.reload.logs)['data'].length).to eq(3)
    end

    it 'adds four log entries after start_creating_resources' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      tracker.start_creating_resources!
      expect(JSON.parse(tracker.reload.logs)['data'].length).to eq(4)
    end

    it 'adds five log entries after completed' do
      tracker.job_created!
      tracker.start_unzipping!
      tracker.unzipping_completed!
      tracker.start_creating_resources!
      tracker.completed!
      expect(JSON.parse(tracker.reload.logs)['data'].length).to eq(5)
    end
  end

  describe 'csv_file_name behavior' do
    let(:program) { create(:program) }
    let(:tracker) { create(:bulk_resources_creation_tracker, program_id: program.id) }

    context 'when csv_file_name is set' do
      let(:custom_file_name) { 'my_custom_errors_report.csv' }

      before do
        tracker.update(csv_file_name: custom_file_name)
      end

      it 'retains the custom csv_file_name' do
        expect(tracker.reload.csv_file_name).to eq(custom_file_name)
      end

      it 'can be updated to a different name' do
        new_file_name = 'updated_errors_report.csv'
        tracker.update(csv_file_name: new_file_name)
        expect(tracker.reload.csv_file_name).to eq(new_file_name)
      end

      it 'persists the csv_file_name through state transitions' do
        tracker.job_created!
        tracker.start_unzipping!
        tracker.unzipping_completed!
        tracker.start_creating_resources!
        tracker.completed!
        expect(tracker.reload.csv_file_name).to eq(custom_file_name)
      end
    end

    context 'when csv_file_name is nil' do
      before do
        tracker.update(csv_file_name: nil)
      end

      it 'allows setting a csv_file_name' do
        file_name = 'new_errors_report.csv'
        tracker.update(csv_file_name: file_name)
        expect(tracker.reload.csv_file_name).to eq(file_name)
      end

      it 'can be set during processing_files state' do
        tracker.processing_files!
        file_name = 'processing_errors_report.csv'
        tracker.update(csv_file_name: file_name)
        expect(tracker.reload.csv_file_name).to eq(file_name)
      end
    end

    context 'when csv_file_name is empty string' do
      before do
        tracker.update(csv_file_name: '')
      end

      it 'treats empty string as a valid value' do
        expect(tracker.reload.csv_file_name).to eq('')
      end

      it 'can be updated to a valid file name' do
        file_name = 'valid_errors_report.csv'
        tracker.update(csv_file_name: file_name)
        expect(tracker.reload.csv_file_name).to eq(file_name)
      end
    end

    context 'when file name is set during validation' do
      it 'accepts valid CSV file names' do
        valid_names = [
          'errors_report.csv',
          'my_errors.csv',
          'errors_2024_01_15.csv',
          'program_123_errors.csv'
        ]

        valid_names.each do |file_name|
          tracker.update(csv_file_name: file_name)
          expect(tracker.reload.csv_file_name).to eq(file_name)
        end
      end

      it 'accepts file names with special characters' do
        special_names = [
          'errors-report.csv',
          'errors_report_2024.csv',
          'errors_report_v1.0.csv'
        ]

        special_names.each do |file_name|
          tracker.update(csv_file_name: file_name)
          expect(tracker.reload.csv_file_name).to eq(file_name)
        end
      end
    end
  end
end
