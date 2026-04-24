include RspecJsContentHelpers
module StandardsMapping
  describe StandardAssetExporter do
    let(:program) { create(:program_with_toc_entries) }
    let!(:activity) { create_true_false_enhanced_activity(program) }
    let!(:standard_asset) do
      create(:standard_asset, vendor_guid: 'ACT-123', reference_type: 'Activity',
                              additional_attrs: { domain: 'Math', subdomain: 'Algebra' })
    end

    before do
      activity.update!(standard_asset:)
    end

    describe '#each' do
      context 'when asset type is activities' do
        let(:exporter) { described_class.new(program.id, 'activity') }

        it 'returns rows of standard asset data for activities' do
          expect(exporter.to_a).to eq([
            {
              'guid' => 'ACT-123',
              'client_id' => activity.cms_activity_id.to_s,
              'title' => activity.title,
              'unit_name' => activity.lesson.unit.name,
              'lesson_name' => activity.lesson.name,
              'strand_name' => activity.concept.name,
              'component_name' => activity.component_name,
              'activity_type' => activity.activity_type,
              'domain' => 'Math',
              'subdomain' => 'Algebra',
              'program_ids' => program.id.to_s,
              'mapped_item_type' => 'Activity',
              'content_url' => "https://cms.vhlcentral.com/activities/#{activity.cms_activity_id}",
              'm3_url' => "https://m3a.vhlcentral.com/sections/0/activities/#{activity.id}",
              'standards_id_list' => activity.standard_asset.standard_alignments.map(
                &:vendor_standard_guid
              ).join(',')
            }
          ])
        end
      end
      context 'when asset type is assessment-item' do
        let(:assessment_concept) { create(:concept_for_test, program:) }
        let!(:assessment) do
          create(
            :activity,
            concept: assessment_concept,
            activity_type: 'exam',
            lesson: activity.lesson
          )
        end
        let!(:standard_asset_assessment) do
          create(
            :standard_asset,
            vendor_guid: 'ASSESS-123',
            reference_type: 'AssessmentItem',
            additional_attrs: { domain: 'Math', subdomain: 'Algebra' }
          )
        end
        let!(:assessment_item) do
          create(:assessment_item, assessment: assessment, guid: 'ASSESS-456').tap do |item|
            item.update!(standard_asset: standard_asset_assessment)
          end
        end
        let(:exporter) { described_class.new(program.id, 'assessment-item') }

        it 'returns rows of standard asset data for assessment items' do
          assessment_details = Activity
          .joins(lesson: [unit: :program])
          .where(cms_activity_id: assessment_item.assessment_id)
          .map do |act|
            {
              concept_name: act.concept&.name,
              lesson_name: act.lesson&.name,
              unit_name: act.lesson&.unit&.name,
              program_id: act.lesson&.unit&.program_id
            }
          end

          formatted_unit_names = assessment_details
            .map { |d| "#{d[:program_id]} - #{d[:unit_name]}" }
            .join(', ')
          formatted_lesson_names = assessment_details
            .map { |d| "#{d[:program_id]} - #{d[:lesson_name]}" }
            .join(', ')
          formatted_strand_names = assessment_details
            .map { |d| "#{d[:program_id]} - #{d[:concept_name]}" }
            .join(', ')

          expect(exporter.to_a).to eq([
            {
              'guid' => 'ASSESS-123',
              'client_id' => 'ASSESS-456',
              'title' => assessment.title,
              'units' => formatted_unit_names,
              'lessons' => formatted_lesson_names,
              'strands' => formatted_strand_names,
              'component_name' => assessment_item.assessment.component_name,
              'activity_type' => assessment_item.assessment.activity_type,
              'domain' => 'Math',
              'subdomain' => 'Algebra',
              'program_ids' => program.id.to_s,
              'mapped_item_type' => 'AssessmentItem',
              'content_url' =>
                "https://cms.vhlcentral.com/activities/#{assessment_item.assessment_id}",
              'm3_url' =>
                'https://m3a.vhlcentral.com/sections/0/activities/' \
                "#{assessment_item.assessment.id}?activate_guid_viewer=true",
              'standards_id_list' =>
                assessment_item.standard_asset.standard_alignments
                .map(&:vendor_standard_guid)
                .join(',')
            }
          ])
        end
      end

      context 'when asset type is te-content' do
        let!(:standard_asset_ereader) do
          create(:standard_asset, vendor_guid: 'TE-123', reference_type: 'EReaderItem',
                                  additional_attrs: { domain: 'Math', subdomain: 'Algebra' })
        end
        let!(:ereader_item) do
          create(:e_reader_item, concept: activity.concept, title: 'E-Book Chapter',
                                 guid: 'TE-789').tap do |item|
            item.update!(standard_asset: standard_asset_ereader)
          end
        end

        let(:exporter) { described_class.new(program.id, 'te-content') }

        it 'returns rows of standard asset data for TE Content' do
          expect(exporter.to_a).to eq([
            {
              'guid' => 'TE-123',
              'client_id' => 'TE-789',
              'title' => 'E-Book Chapter',
              'page_number' => ereader_item.page_number,
              'descriptor' => ereader_item.descriptor,
              'concept_name' => ereader_item.concept&.name,
              'unit_name' => 'Lesson 1',
              'domain' => 'Math',
              'subdomain' => 'Algebra',
              'program_ids' => program.id.to_s,
              'content_url' => 'https://cms.vhlcentral.com',
              'mapped_item_type' => 'TEContent',
              'standards_id_list' => standard_asset_ereader.standard_alignments.map(
                &:vendor_standard_guid
              ).join(',')
            }
          ])
        end
      end
    end
  end
end
