module OneRoster
  describe CourseSectionUpdaterWorker do
    let(:school) { create(:one_roster_school) }
    let(:course1) { create(:course, school: school) }
    let(:course2) { create(:course, school: school) }
    let(:section1) { create(:section, course: course1) }
    let(:section2) { create(:section, course: course2) }
    let(:course_external_id) { 'ra_course_1'}
    let!(:linked_section_1) { create(:one_roster_linked_section, section: section1, course_external_id: course_external_id, school: school) }
    let!(:linked_section_2) { create(:one_roster_linked_section, section: section2, course_external_id: course_external_id, school: school) }
    let(:config) { instance_double('config') }
    let(:redis_cache) { instance_double('mock_redis') }
    let (:orcsu_wc_key) { format(CourseSectionUpdaterWorker::ORCSU_IN_PROGRESS_KEY, school_id: school.id) }

    let(:updater) do
      instance_double(OneRoster::CourseSectionUpdater, update: true, errors: true)
    end
    # let(:linked_users) { [linked_user1, linked_user2] }
    let(:worker) { described_class.new }

    before do
      allow(OneRoster::CourseSectionUpdater).to receive(:new).and_return(updater)
      allow(updater).to receive(:errors).and_return(nil)
      allow(worker).to receive(:logger_data_merge)
      allow(M3::Application).to receive(:config).and_return(config)
      allow(config).to receive(:job_conflict_cache).and_return(redis_cache)
      allow(Sidekiq).to receive(:redis).and_return(redis_cache)
      allow(redis_cache).to receive(:keys).with(orcsu_wc_key)
                                          .and_return([])
      allow(redis_cache).to receive(:set).and_return(true)
      allow(redis_cache).to receive(:del).and_return(true)
    end

    it 'creates a OneRoster::CourseSectionUpdater object' do
      worker.perform(school.id)
      expect(OneRoster::CourseSectionUpdater).to have_received(:new)
        .with(school.id, course_external_id).once
    end

    it 'updates the linked sections' do
      worker.perform(school.id)
      expect(updater).to have_received(:update).once
    end

    it 'logs the process to logstash' do
      worker.perform(school.id)
      expect(worker).to have_received(:logger_data_merge)
        .with(school_id: school.id).once
    end

    it 'logs any error to logstash' do
      errors = ['Saving section failed']
      allow(updater).to receive(:errors).and_return(errors)
      worker.perform(school.id)
      expect(worker).to have_received(:logger_data_merge)
        .with(error_key: school.id, course_section_updater_error: 'Saving section failed')
    end

    it 'logs error if job for same school is in process' do
      allow(redis_cache).to receive(:keys).with(orcsu_wc_key)
                                          .and_return([orcsu_wc_key])
      worker.perform(school.id)
      expect(worker).to have_received(:logger_data_merge)
                            .with(error_key: school.id, course_section_updater_error: 'job is currently in process for this school')
    end
  end
end
