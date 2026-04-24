# encoding: utf-8

describe ActivityPublishProcessor do
  let(:program) do
    create(
      :program,
      title: 'Book 1',
      vhlcentral_subdomain: 'Book 1'.parameterize.to_s
    )
  end
  let(:unit) { create(:unit, program: program, rank: 1) }
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, unit: unit, rank: 0, toc_entries: [strand]) }
  let(:concept) do
    create(:concept, id: strand.location, lesson: lesson, program: program)
  end
  let!(:content_xml) { File.read('spec/fixtures/xml/exam.xml') }
  let!(:openended_content) { File.read('spec/fixtures/xml/open_ended.xml') }
  let(:new_revision_id) { 2 }
  let(:association_params) do
    {
      'content' => nil,
      'lesson_id' => lesson.id,
      'lesson_rank' => lesson.rank,
      'program_id' => program.id,
      'unit_rank' => unit.rank
    }
  end
  let(:activity_params) do
    {
      'assignment_group' => 'Practice',
      'cdn' => false,
      'cms_activity_id' => 1,
      'cms_revision_id' => new_revision_id,
      'component_name' => 'Component 1',
      'concept_id' => concept.id,
      'concept_rank' => 1,
      'icon' => 'some_icon_name',
      'license_group_id' => 4,
      'page' => '3',
      'title' => 'Activity 1',
      'toc_location' => strand.location.to_i,
      'toc_location_rank' => 1
    }
  end

  let(:params) { activity_params.merge(association_params) }
  let(:processor) { described_class.new(params.dup) }
  let(:cms_updater_klass) { ActivityPublishProcessor::CmsRevisionUpdater }

  it 'includes BasePublishProcessor' do
    expect(processor).to be_a BasePublishProcessor
  end

  describe '#process_request' do
    let(:updater) do
      instance_double(
        cms_updater_klass,
        current_version_has_already_been_published?: true,
        updated_activities: []
      )
    end

    before do
      allow(cms_updater_klass).to receive(:new).and_return(updater)
      allow(updater).to receive(:update_revision_ids_and_cdn).and_return(updater)
      lesson.toc_entries = [strand]
      lesson.save!
      allow(StandardAsset).to receive(:update_published_status)
    end

    it 'finds a unit by the given program_id and rank params' do
      expect(Unit).to receive(:find_by_program_id_and_rank)
        .with(params['program_id'], params['unit_rank'])
        .and_return(unit)
      processor.process_request
    end

    it 'finds a lesson by the unit id previously found and lesson rank param' do
      expect(Lesson).to receive(:find_by_unit_id_and_rank)
        .with(unit.id, params['lesson_rank'])
        .and_return(lesson)
      processor.process_request
    end

    it 'sets lesson id value in the processor request params when a lesson is found' do
      processor.process_request
      expect(processor.request['lesson_id']).to eq(lesson.id)
    end

    it 'does an activity lookup by cms_activity_id and lesson_id' do
      expect(Activity).to receive(:find_by).with(
        cms_activity_id: params['cms_activity_id'],
        lesson_id: params['lesson_id']
      ).and_return([])
      processor.process_request
    end

    context 'when an activity with the search params is found' do
      let(:activity) do
        build(
          :activity,
          cdn: false,
          cms_activity_id: 1,
          cms_revision_id: 1,
          concept: concept,
          lesson: lesson,
          toc_location: strand.location
        )
      end

      before do
        allow(activity.activity_content).to receive(:content)
          .and_return(openended_content)
        activity.save!
      end

      context 'when activity is meant to be updated' do
        let(:processor) { described_class.new(params.merge('perform' => 'update')) }

        it 'instantiates a CmsRevisionUpdater object and calls its update_revision_ids method' do
          expect(cms_updater_klass).to receive(:new)
            .with(activity, new_revision_id, false, params['icon'])
            .and_return(updater)
          expect(updater).to receive(:update_revision_ids_and_cdn)
          processor.process_request
        end

        it "updates activity's attributes using posted params" do
          expected_attributes = activity_params.dup
          expected_attributes.delete('cms_revision_id') # This is updated within CmsRevisionUpdater
          processor.process_request
          updated_attributes = Activity.find_by_title(activity_params['title']).attributes
          expect(updated_attributes).to include(expected_attributes)
        end

        context 'when all activities need update' do
          before do
            allow(updater).to receive(:current_version_has_already_been_published?)
              .and_return(false)
          end

          context 'when assigning content' do
            let(:study_plan) { create(:activity, activity_type: 'study_plan_practice_test') }

            before do
              allow(Activity).to receive(:find_by).and_return(activity)
            end

            context 'when the object to publish is a study plan practice test' do
              it 'creates study plan concepts based on the object to pubilsh' do
                allow(updater).to receive(:updated_activities).and_return([])
                allow(activity).to receive(:activity_type).and_return('study_plan_practice_test')

                expect(StudyPlanConceptsCreator).to receive(:batch_create)
                  .with([activity], association_params['program_id'])

                described_class.new(params).process_request
              end
            end

            context 'when the updated activities are study plan practice test activities' do
              it 'creates study plan concepts based on the updated activities' do
                allow(updater).to receive(:updated_activities).and_return([study_plan])

                expect(StudyPlanConceptsCreator).to receive(:batch_create)
                  .with([study_plan], association_params['program_id'])

                described_class.new(params).process_request
              end
            end

            context 'when the updated activities includes a study plan practice test activity' do
              it 'creates study plan concepts on the study plan practice test activity only' do
                other_activity = create(:activity)

                allow(updater).to receive(:updated_activities)
                  .and_return([study_plan, other_activity])

                expect(StudyPlanConceptsCreator).to receive(:batch_create)
                  .with([study_plan], association_params['program_id'])

                described_class.new(params).process_request
              end
            end
          end

          it 'sets content_summary correctly' do
            activity = Activity.last
            allow(activity.activity_content).to receive(:content).and_return(content_xml)
            activity.save
            processor.process_request
            updated_activity = Activity.find_by_title(activity_params['title'])
            expect(updated_activity.content_summary).to eq({ fill_in_the_blanks: 17 })
          end

          it 'writes the content to disk if not live' do
            allow(Rails.env).to receive(:live?).and_return(false)
            allow(Activity).to receive(:find_by).and_return(activity)
            expect(activity).to receive(:content=)

            processor.process_request
          end

          it "does not write content to disk when live" do
            allow(Rails.env).to receive(:live?).and_return(true)
            allow(Activity).to receive(:find_by).and_return(activity)
            expect(activity).to_not receive(:content=)

            processor.process_request
          end
        end

        it 'does not assign the posted content if the current version has already been published' do
          allow(Activity).to receive(:where).and_return([activity])
          expect(activity).to_not receive(:content=)

          processor.process_request
        end
      end

      context 'when activity is meant to be removed' do
        it 'removes toc_entry association for the given activity' do
          ActivityPublishProcessor.new(params.merge('perform' => 'remove')).process_request
          activity.reload
          expect(activity.toc_location).to be_nil
          expect(activity.toc_location_rank).to be_nil
        end
      end
    end

    context 'when activity with the search params is not found' do
      context 'when creating a new activity' do
        it 'creates a new Activity instance using the posted params' do
          processor.process_request
          new_activity = Activity.find_by_title(activity_params['title'])
          expect(new_activity.attributes).to include(activity_params)
        end
        context 'when activity is a study plan practice test' do
          it 'creates study plan concepts based on the created activity' do
            expect(StudyPlanConceptsCreator).to receive(:batch_create)
              .with(anything, association_params['program_id'])
            params['activity_type'] = 'study_plan_practice_test'
            processor = described_class.new(params)
            processor.process_request
          end
        end
      end

      it "updates revision id in related activities using updater class" do
        expect(ActivityPublishProcessor::CmsRevisionUpdater).to receive(:new)
        expect(updater).to receive(:update_revision_ids_and_cdn)
        processor.process_request
      end
    end
  end
end

describe ActivityPublishProcessor::CmsRevisionUpdater do
  let(:old_revision_id) { 565 }
  let(:new_revision_id) { 567 }

  let!(:object_to_publish) do
    build(
      :activity, cms_activity_id: 1,
      cms_revision_id: new_revision_id,
      cdn: false
    )
  end

  let(:updater) do
    ActivityPublishProcessor::CmsRevisionUpdater.new(
      object_to_publish, new_revision_id, false, object_to_publish.icon
    )
  end

  describe '#current_version_has_already_been_published?' do
    it 'is true when at least one of all related activities has the new revision id' do
      create(:activity, cms_activity_id: 1, cms_revision_id: new_revision_id)
      expect(updater.current_version_has_already_been_published?).to be_truthy
    end

    it 'is false when none of the related activities has the new revision id' do
      create(:activity, cms_activity_id: 1, cms_revision_id: old_revision_id)
      expect(updater.current_version_has_already_been_published?).to be_falsey
    end
  end

  describe '#update_revision_ids_and_cdn', test_debt: true do
    let!(:related_activity) do
      create(
        :activity,
        title: 'Related activity',
        cdn: true,
        cms_activity_id: 1,
        cms_revision_id: old_revision_id
      )
    end

    before do
      stub_request(
        :any,
        %r{https\://s3\.amazonaws\.com/vhlcentral.activities/.*\.xml}
      ). to_return(status: 200, body: '', headers: {})
    end

    it 'updates revision id for activity to be published' do
      updater.update_revision_ids_and_cdn
      expect(object_to_publish.cms_revision_id).to eq new_revision_id
    end

    it 'updates revision id for all related activities that have a concept' do
      related_activity_without_concept = create(
        :activity,
        title: 'Other related activity',
        cdn: true,
        cms_activity_id: 1,
        cms_revision_id: old_revision_id
      )
      related_activity_without_concept.concept.destroy
      updater.update_revision_ids_and_cdn
      expect(related_activity.reload.cms_revision_id).to eq new_revision_id
      expect(related_activity_without_concept.reload.cms_revision_id).to eq old_revision_id
    end

    it 'updates cdn for all related activities' do
      updater.update_revision_ids_and_cdn
      expect(related_activity.reload.cdn).to be_falsey
    end

    it 'updates cdn for all related activities when revision_id has not changed' do
      related_activity = Activity.find_by_title('Related activity')
      related_activity.update(cms_revision_id: new_revision_id)
      updater.update_revision_ids_and_cdn
      expect(related_activity.reload.cdn).to be_falsey
    end

    describe 'updating activity icon' do
      let(:expected_icon) { 'audio,video' }

      before do
        object_to_publish.update!(icon: expected_icon)
      end

      it 'sets the icon of all related activities, if they have none' do
        related_activity.update!(icon: nil)
        updater.update_revision_ids_and_cdn
        expect(related_activity.reload.icon).to eq expected_icon
      end

      it 'does not set the textbook icon on related activities if it does not have it' do
        object_to_publish.update!(icon: 'audio,textbook')
        updater.update_revision_ids_and_cdn
        expect(related_activity.reload.icon).to eq 'audio'
      end

      it 'updates the icon of all related activities' do
        related_activity.update!(icon: 'other_icon')
        updater.update_revision_ids_and_cdn
        expect(related_activity.reload.icon).to eq expected_icon
      end

      it 'keeps the textbook icon on related activities, if has it' do
        related_activity.update!(icon: 'other_icon,textbook')
        updater.update_revision_ids_and_cdn
        expect(related_activity.reload.icon).to eq 'audio,video,textbook'
      end
    end
  end
end
