module Cartridge
  describe ArchiveClosedCoursesWorker do
    let(:config) { instance_double('config') }
    let(:redis_cache) { instance_double('mock_redis') }
    let(:worker) { described_class.new }

    let(:school) { create(:school) }
    let(:expired_course) { create(:expired_course, school: school) }
    let(:section) do
      create(:section_with_enrollments,
             course: expired_course,
             number_of_enrollments: 2)
    end
    let!(:course_context_detail) do
      create(:cartridge_course_context_detail,
             course: expired_course,
             section: section,
             school: school)
    end

    before do
      allow(M3::Application).to receive(:config).and_return(config)
      allow(redis_cache).to receive(:del).and_return(true)
      allow(redis_cache).to receive(:keys).with(described_class::CC_IN_PROGRESS_KEY)
                                          .and_return([])
      allow(redis_cache).to receive(:set).with(described_class::CC_IN_PROGRESS_KEY, true)
                                         .and_return([described_class::CC_IN_PROGRESS_KEY])
      allow(config).to receive(:job_conflict_cache).and_return(redis_cache)
      allow(Sidekiq).to receive(:redis).and_return(redis_cache)
      allow(worker).to receive(:logger_data_merge)
      allow(worker).to receive(:in_progress)
    end

    describe '#perform' do
      it 'logs an error when a job is already running' do
        allow(redis_cache).to receive(:keys).with(described_class::CC_IN_PROGRESS_KEY)
                                            .and_return([described_class::CC_IN_PROGRESS_KEY])
        worker.perform
        expect(worker).to have_received(:logger_data_merge)
          .with(error_key: described_class::CC_IN_PROGRESS_KEY,
                cc_archive_error: 'job is currently in process')
      end

      it 'processes the job without conflict' do
        worker.perform
        expect(worker).to have_received(:in_progress).with(described_class::CC_IN_PROGRESS_KEY)
      end
    end

    describe '#archive_closed_course' do
      it 'archives the course context detail' do
        worker.archive_closed_course(course_context_detail: course_context_detail,
                                     course: expired_course,
                                     section: section)
        expect(course_context_detail.reload.is_archived).to be true
      end

      it 'archives the course' do
        worker.archive_closed_course(course_context_detail: course_context_detail,
                                     course: expired_course,
                                     section: section)
        expect(expired_course.reload.is_archived).to be true
      end

      it 'archives the section' do
        worker.archive_closed_course(course_context_detail: course_context_detail,
                                     course: expired_course,
                                     section: section)
        expect(section.reload.is_archived).to be true
      end

      it 'archives the enrollments' do
        worker.archive_closed_course(course_context_detail: course_context_detail,
                                     course: expired_course,
                                     section: section)
        section.reload.enrollments.each do |enrollment|
          expect(enrollment.state).to eq 'archived'
        end
      end

      context 'when the section can not be archived' do
        it 'does not archive the course' do
          allow(section).to receive(:update).and_return(false)
          worker.archive_closed_course(course_context_detail: course_context_detail,
                                       course: expired_course,
                                       section: section)
          expect(expired_course.reload.is_archived).to be false
        end

        it 'does not archive the course context detail' do
          allow(section).to receive(:update).and_return(false)
          worker.archive_closed_course(course_context_detail: course_context_detail,
                                       course: expired_course,
                                       section: section)
          expect(course_context_detail.reload.is_archived).to be false
        end

        it 'logs the error message' do
          allow(section).to receive(:update).and_return(false)
          worker.archive_closed_course(course_context_detail: course_context_detail,
                                       course: expired_course,
                                       section: section)
          expect(worker).to have_received(:logger_data_merge).twice
        end
      end

      context 'when the course context detail can not be archived' do
        it 'does not archive the section' do
          allow(course_context_detail).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
          worker.archive_closed_course(course_context_detail: course_context_detail,
                                       course: expired_course,
                                       section: section)
          expect(section.reload.is_archived).to be false
        end

        it 'does not archive the course' do
          allow(course_context_detail).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
          worker.archive_closed_course(course_context_detail: course_context_detail,
                                       course: expired_course,
                                       section: section)
          expect(expired_course.reload.is_archived).to be false
        end

        it 'logs the error message' do
          allow(course_context_detail).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
          worker.archive_closed_course(course_context_detail: course_context_detail,
                                       course: expired_course,
                                       section: section)
          expect(worker).to have_received(:logger_data_merge).once
        end
      end
    end
  end
end
