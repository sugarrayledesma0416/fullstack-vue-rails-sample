describe StandardsAssigningPresenter do
  include StandardsAssigningHelpers

  # shared set for a program/course supporting two standard sets.
  # program supports: standard_set_1, standard_set_2
  # course config has: standard_set_1, standard_set_2
  shared_context 'with standards_course' do
    # program_with_lessons factory creates program w/3 units that each have 2 lessons.
    let(:program) { create(:program_with_lessons) }
    let(:course) { create(:course) }
    let(:standards_program) { create(:program_with_lessons) }

    let(:standard_set_1) { create(:standard_set, display_name: 'dn 1') }
    let(:standard_set_2) { create(:standard_set, display_name: 'dn 2') }

    let(:standards_course) do
      create(:course_with_section,
             program: standards_program,
             standard_set_ids: [standard_set_1.id, standard_set_2.id])
    end

    before do
      create(
        :program_config_with_standard_sets,
        program: standards_program,
        supported_standard_sets: [standard_set_1, standard_set_2]
      )
    end
  end

  shared_context 'activities_and_alignments' do
    # rubocop:disable RSpec/LetSetup
    # disabling because rubocop doesn't see into StandardsAssigningHelpers module,
    # and complains about standard_1, standard_2 not being used.

    # Set up activities, a TE item and an exam expected to be selected for payload
    let!(:activity_1) { create(:activity, lesson: program.lessons.first, icon: 'microphone') }
    let!(:activity_2) do
      create(
        :activity,
        lesson: program.lessons.last,
        icon: 'microphone',
        activity_type: 'open_ended'
      )
    end

    let(:assessment_lesson) do
      create(:lesson_with_assessment_toc_entries, unit: program.units.last)
    end
    let(:concept) { create(:concept_for_test, lesson: assessment_lesson, program:) }
    let!(:exam) do
      create(:activity, lesson: assessment_lesson, concept:, activity_type: 'exam')
    end

    # Set up standard assets
    let(:standard_asset_1) { create(:standard_asset, reference_id: activity_1.cms_activity_id) }
    let(:standard_asset_2) { create(:standard_asset, reference_id: activity_2.cms_activity_id) }
    let(:assessment_item) { create(:assessment_item, assessment_id: exam.cms_activity_id) }
    let(:standard_asset_3) do
      create(:standard_asset_assessment_item, assessment_item:)
    end
    let(:ereader_item) { create(:e_reader_item, concept:) }
    let(:standard_asset_4) do
      create(:standard_asset_ereader_item, ereader_item:)
    end

    # Set up standards that belong to sets within the course configration
    let(:standard_1) do
      create(:standard, vendor_standard_set_guid: standard_set_1.vendor_guid)
    end
    let(:standard_2) do
      create(:standard, vendor_standard_set_guid: standard_set_2.vendor_guid)
    end

    # Set up standard alignments
    let!(:standard_alignment_1) do
      create(
        :standard_alignment,
        standard_asset: standard_asset_1,
        vendor_standard_guid: standard_1.vendor_guid
      )
    end

    let!(:standard_alignment_2) do
      create(
        :standard_alignment,
        standard_asset: standard_asset_2,
        vendor_standard_guid: standard_2.vendor_guid
      )
    end

    let!(:standard_alignment_3) do
      create(
        :standard_alignment,
        standard_asset: standard_asset_3,
        vendor_standard_guid: standard_2.vendor_guid
      )
    end

    let!(:standard_alignment_4) do
      create(
        :standard_alignment,
        standard_asset: standard_asset_4,
        vendor_standard_guid: standard_2.vendor_guid
      )
    end
  end

  describe '#toc' do
    include_context 'with standards_course'
    it 'returns toc json for the program' do
      presenter = described_class.new(program, standards_course.sections, standards_course)
      # TODO: expand to cover toc's that show lessons, two tier books
      units = program.units.map do |unit|
        { id: unit.id, name: unit.name }
      end
      concepts = program.concepts.each_with_object({}) do |con, hash|
        hash[con.id] = con.name
      end
      toc_json = {
        units:,
        concepts:
      }.to_json
      expect(presenter.toc).to eq(toc_json)
    end
  end

  describe '#availabe_sets' do
    it 'returns an empty array if the program does not support standards' do
      program_no_standards_config = create(:program)
      course = create(:course)
      presenter = described_class.new(program_no_standards_config, course)
      expect(presenter.available_sets).to eq([])
    end

    context 'with standards configuration' do
      include_context 'with standards_course'
      it 'returns the sets supported for programs that support standards' do
        presenter = described_class.new(program, standards_course)
        expect(presenter.available_sets)
          .to eq([standard_set_1.display_name, standard_set_2.display_name])
      end
    end
  end

  describe '#assets_and_standards_payload' do
    context 'with a successful result from StandardsSearch' do
      include_context 'with standards_course'
      include_context 'activities_and_alignments'

      it 'returns the assets and standards payload as json' do
        selected_standards = %w[a_guid another_guid]
        presenter_for_assets_search = described_class.new(
          program,
          standards_course.sections,
          standards_course,
          selected_standards:
        )
        assets_searcher = instance_double(StandardsMapping::StandardsSearch)
        allow(assets_searcher)
          .to receive(:search_standard_assets)
          .with(selected_standards, program.id,
            {
              next_key: nil,
              selected_content_type: [],
              selected_refinements: [],
              selected_skills: [],
              unit_id: [program.lessons.first.unit_id]
            }
          )
          .and_return(os_assets_result)
        allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(assets_searcher)
        presenter_for_assets_search.assets_and_standards_payload.each do |key, value|
          # converting JSON strings to hashes to compare them
          # as hashes which aren't order dependent
          expect(JSON.parse(value)).to eq(JSON.parse(assets_and_standards_payload[key]))
        end
      end

      context 'with a cms_activity_id associated with the Open Search payload,' \
              'but not in current program' do
        let(:not_current_program) { create(:program_with_lessons) }
        let(:concept_not_current_program) do
          create(:concept_with_calculated_combined_rank,
                 lesson: not_current_program.lessons.first,
                 program: not_current_program)
        end

        it 'does not pull in the activity info unless it is in the current program' do
          create(
            :activity,
            # cms_activity_id from Open Search with not current program.
            cms_activity_id: activity_1.cms_activity_id,
            concept: concept_not_current_program,
            lesson: concept_not_current_program.lesson
          )
          selected_standards = %w[a_guid another_guid]
          presenter_for_assets_search = described_class.new(
            program,
            standards_course.sections,
            standards_course,
            selected_standards:
          )
          assets_searcher = instance_double(StandardsMapping::StandardsSearch)
          allow(assets_searcher)
            .to receive(:search_standard_assets)
            .with(selected_standards, program.id,
              {
                next_key: nil,
                selected_content_type: [],
                selected_refinements: [],
                selected_skills: [],
                unit_id: [program.lessons.first.unit_id]
              }
            ).and_return(os_assets_result)
          allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(assets_searcher)
          presenter_for_assets_search.assets_and_standards_payload.each do |key, value|
            # converting JSON strings to hashes to compare them
            # as hashes which aren't order dependent
            expect(JSON.parse(value)).to eq(JSON.parse(assets_and_standards_payload[key]))
          end
        end
      end

      context 'with result from Open Search that maps to an activity with nil toc' do
        # Correct program, but nil toc
        let!(:activity_nil_toc) do
          create(:activity, lesson: program.lessons.last, toc_location: nil)
        end

        let(:standard_asset_nil_toc) do
          create(:standard_asset, reference_id: activity_nil_toc.cms_activity_id)
        end
        let!(:standard_alignment_nil_toc) do
          create(
            :standard_alignment,
            standard_asset: standard_asset_nil_toc,
            vendor_standard_guid: standard_2.vendor_guid
          )
        end

        it 'does not return results associated with the nil toc activity' do
          selected_standards = %w[a_guid another_guid]
          presenter_for_assets_search = described_class.new(
            program,
            standards_course.sections,
            standards_course,
            selected_standards:
          )
          assets_searcher = instance_double(StandardsMapping::StandardsSearch)
          allow(assets_searcher)
            .to receive(:search_standard_assets)
            .with(selected_standards, program.id,
              {
                next_key: nil,
                selected_content_type: [],
                selected_refinements: [],
                selected_skills: [],
                unit_id: [program.lessons.first.unit_id]
              }
            )
            .and_return(os_asset_result_with_nil_toc_activity)
          allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(assets_searcher)
          presenter_for_assets_search.assets_and_standards_payload.each do |key, value|
            # converting JSON strings to hashes to compare them
            # as hashes which aren't order dependent
            expect(JSON.parse(value)).to eq(JSON.parse(assets_and_standards_payload[key]))
          end
        end
      end

      context 'With an alignment mapping to a StandardAsset returned by OpenSearch that belongs' \
              'to a standard outside of the course configuration standard sets.' do
        let(:standard_set_not_in_course_config) { create(:standard_set) }
        let(:standard_not_in_course_config) do
          create(:standard, vendor_standard_set_guid: standard_set_not_in_course_config.vendor_guid)
        end

        let!(:standard_alignment_set_not_in_course_config) do
          create(
            :standard_alignment,
            standard_asset: standard_asset_1, # This asset id is returned from the OS payload.
            vendor_standard_guid: standard_not_in_course_config.vendor_guid
          )
        end

        it 'does not include the result mapped to a standard outside the course config' do
          selected_standards = %w[a_guid another_guid]
          presenter_for_assets_search = described_class.new(
            program,
            standards_course.sections,
            standards_course,
            selected_standards:
          )
          assets_searcher = instance_double(StandardsMapping::StandardsSearch)
          allow(assets_searcher)
            .to receive(:search_standard_assets)
            .with(selected_standards, program.id,
              {
                next_key: nil,
                selected_content_type: [],
                selected_refinements: [],
                selected_skills: [],
                unit_id: [program.lessons.first.unit_id]
              }
            )
            .and_return(os_assets_result)
          allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(assets_searcher)
          presenter_for_assets_search.assets_and_standards_payload.each do |key, value|
            # converting JSON strings to hashes to compare them
            # as hashes which aren't order dependent
            expect(JSON.parse(value)).to eq(JSON.parse(assets_and_standards_payload[key]))
          end
        end
      end

      context 'when there are multiple mappings to an assessment' do
        let(:assessment_lesson) do
          create(:lesson_with_assessment_toc_entries, unit: program.units.last)
        end
        let(:concept) { create(:concept_for_test, lesson: assessment_lesson) }
        let!(:exam) do
          create(:activity, lesson: assessment_lesson, concept:, activity_type: 'exam')
        end

        # Data setup notes:
        # Assert that the AssessmentItem alignment data rolls up to the Activty level
        # properly:
        # 1) Set up 3 AssessmentItem records that point to a single assessment.
        # 2) Two of the AssessmentItem records should map to 2 different standards from within
        # the same standard set.
        # 3) The third AssessmentItem record should map to a standard in another standard set.
        # 4) Make sure stubbed OpenSearch results account for the items in the above 3 steps
        #
        # Assert that AssessmentItem records belonging to a common activity that map
        # to the same standard do not produce duplicated Standard or Standard Set entries within
        # an activity key:
        # 1) Set up an Assessment Item pointing to the common assessment from above steps.
        # 2) Create setup so that the alignment points to a standard that already has an
        # alignment pointing to it.
        # 3) Make sure the stubbed OpenSearch results account for this item.

        let(:assessment_item_1) { create(:assessment_item, assessment_id: exam.cms_activity_id) }
        let(:assessment_item_2) { create(:assessment_item, assessment_id: exam.cms_activity_id) }
        let(:assessment_item_2a) { create(:assessment_item, assessment_id: exam.cms_activity_id) }
        let(:assessment_item_2a_duplicate) do
          create(:assessment_item, assessment_id: exam.cms_activity_id)
        end
        let(:standard_asset_for_ai_1) do
          create(:standard_asset_assessment_item, assessment_item: assessment_item_1)
        end
        let(:standard_asset_for_ai_2) do
          create(:standard_asset_assessment_item, assessment_item: assessment_item_2)
        end
        let(:standard_asset_for_ai_2a) do
          create(:standard_asset_assessment_item, assessment_item: assessment_item_2a)
        end
        let(:standard_asset_for_ai_2a_duplicate) do
          create(:standard_asset_assessment_item, assessment_item: assessment_item_2a_duplicate)
        end

        let(:standard_1) { create(:standard, vendor_standard_set_guid: standard_set_1.vendor_guid) }

        let(:standard_2) { create(:standard, vendor_standard_set_guid: standard_set_2.vendor_guid) }
        let(:standard_2a) do
          create(:standard, vendor_standard_set_guid: standard_set_2.vendor_guid)
        end

        let!(:standard_alignment_1) do
          create(
            :standard_alignment,
            standard_asset: standard_asset_for_ai_1,
            vendor_standard_guid: standard_1.vendor_guid
          )
        end
        let!(:standard_alignment_2) do
          create(
            :standard_alignment,
            standard_asset: standard_asset_for_ai_2,
            vendor_standard_guid: standard_2.vendor_guid
          )
        end
        let!(:standard_alignment_2a) do
          create(
            :standard_alignment,
            standard_asset: standard_asset_for_ai_2a,
            vendor_standard_guid: standard_2a.vendor_guid
          )
        end
        let!(:standard_alignment_2a_duplicate) do
          create(
            :standard_alignment,
            standard_asset: standard_asset_for_ai_2a_duplicate,
            vendor_standard_guid: standard_2a.vendor_guid
          )
        end

        it 'rolls up the results' do
          selected_standards = %w[a_guid another_guid]
          presenter_for_assets_search = described_class.new(
            program,
            standards_course.sections,
            standards_course,
            selected_standards:
          )
          assets_searcher = instance_double(StandardsMapping::StandardsSearch)
          allow(assets_searcher)
            .to receive(:search_standard_assets)
            .with(selected_standards, program.id,
                  {
                    next_key: nil,
                    selected_content_type: [],
                    selected_refinements: [],
                    selected_skills: [],
                    unit_id: [program.lessons.first.unit_id]
                  })
            .and_return(os_assets_assessment_multiple_mappings)
          allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(assets_searcher)
          presenter_for_assets_search.assets_and_standards_payload.each do |key, value|
            # converting JSON strings to hashes to compare them
            # as hashes which aren't order dependent

            expect(JSON.parse(value))
              .to eq(JSON.parse(assets_and_standards_payload_assessment_multiple_mappings[key]))
          end
        end
      end
      # rubocop:enable RSpec/LetSetup
    end

    context 'with a server error from StandardsSearch' do
      include_context 'with standards_course'
      it 'raises an error' do
        selected_standards = %w[a_guid another_guid]
        presenter_for_standards_search = described_class.new(program, standards_course,
                                                             selected_standards:)
        standards_searcher = instance_double(StandardsMapping::StandardsSearch)

        # StandardsSearch returns a string explaining the problem on non 200 status.
        # Otherwise, retuns an Array.
        allow(standards_searcher)
          .to receive(:search_standard_assets)
          .with(selected_standards, program.id,
            {
              next_key: nil,
              selected_content_type: [],
              selected_refinements: [],
              selected_skills: [],
              unit_id: [program.lessons.first.unit_id]
            }
          )
          .and_return('error message')
        allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(standards_searcher)

        expect do
          presenter_for_standards_search.assets_and_standards_payload
        end.to raise_error(StandardError, 'error message')
      end
    end
  end

  describe '#matching_standards' do
    let(:search_term) { 'puppies' }
    include_context 'with standards_course'

    context 'with a successful result from StandardsSearch' do
      let(:standard_set) { create(:standard_set) }

      it 'returns the OpenSearch result as json' do
        create(
          :program_config_with_standard_sets,
          program:,
          supported_standard_sets: [standard_set]
        )
        presenter_for_standards_search = described_class.new(
          program,
          standards_course,
          standard_set_vendor_guid: standard_set.vendor_guid,
          search_term:
        )
        expected_standards = [{ cool: 'result' }]
        standards_searcher = instance_double(StandardsMapping::StandardsSearch)
        allow(standards_searcher)
          .to receive(:search_standards)
          .with(
            [standard_set.vendor_guid],
            search_term,
            %w[K 1 2 3 4 5 6 7 8 9 10 11 12],
            program.id
          )
          .and_return(expected_standards)
        allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(standards_searcher)
        expect(presenter_for_standards_search.matching_standards).to eq(expected_standards.to_json)
      end
    end

    context 'with a server error from StandardsSearch' do
      let(:standard_set) { create(:standard_set) }

      it 'returns an error' do
        create(
          :program_config_with_standard_sets,
          program:,
          supported_standard_sets: [standard_set]
        )
        presenter_for_standards_search = described_class.new(
          program,
          standards_course,
          standard_set_vendor_guid: standard_set.vendor_guid,
          search_term:
        )
        standards_searcher = instance_double(StandardsMapping::StandardsSearch)

        # StandardsSearch returns a string explaining the problem on non 200 status.
        # Otherwise, retuns an Array.
        allow(standards_searcher)
          .to receive(:search_standards)
          .with(
            [standard_set.vendor_guid],
            search_term,
            %w[K 1 2 3 4 5 6 7 8 9 10 11 12],
            program.id
          )
          .and_return('error message')
        allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(standards_searcher)
        expect do
          presenter_for_standards_search.matching_standards
        end.to raise_error(StandardError, 'error message')
      end
    end
  end

  describe '#browse_standards' do
    include_context 'with standards_course'

    let(:standard_set) { create(:standard_set) }

    context 'with a successful result from StandardsSearch' do
      it 'returns the browsed standards result' do
        create(
          :program_config_with_standard_sets,
          program:,
          supported_standard_sets: [standard_set]
        )

        presenter_for_standards_search = described_class.new(
          program,
          standards_course,
          standard_set_vendor_guid: standard_set.vendor_guid,
        )

        expected_standards = [{ cool: 'result' }]
        standards_searcher = instance_double(StandardsMapping::StandardsSearch)

        allow(standards_searcher)
          .to receive(:browse_standards)
          .with(
            [standard_set.vendor_guid],
            program.standard_grade_levels,
            program.id
          )
          .and_return(expected_standards)

        allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(standards_searcher)

        expect(presenter_for_standards_search.browse_standards).to eq(expected_standards)
      end
    end
  end


  describe StandardsAssigningPresenter::AlignmentItemSorter do
    include_context 'with standards_course'
    include_context 'activities_and_alignments'

    let(:cms_activity_ids) do
      [
        activity_1.cms_activity_id,
        activity_2.cms_activity_id,
        exam.cms_activity_id,
        assessment_item.assessment_id
      ]
    end

    let(:grouped_standard_alignments) do
      {
        standard_alignment_1.standard_asset_id.to_s => [
          { standardSetGuid: standard_1.vendor_standard_set_guid,
            standardGuid: standard_1.vendor_guid,
            standardSetDisplayName: standard_1.standard_set.display_name
          }
        ],
        standard_alignment_2.standard_asset_id.to_s => [
          { standardSetGuid: standard_2.vendor_standard_set_guid,
            standardGuid: standard_2.vendor_guid,
            standardSetDisplayName: standard_2.standard_set.display_name
          }

        ],
        standard_alignment_3.standard_asset_id.to_s => [
          { standardSetGuid: standard_2.vendor_standard_set_guid,
            standardGuid: standard_2.vendor_guid,
            standardSetDisplayName: standard_2.standard_set.display_name
          }

        ],
        standard_alignment_4.standard_asset_id.to_s => [
          { standardSetGuid: standard_2.vendor_standard_set_guid,
            standardGuid: standard_2.vendor_guid,
            standardSetDisplayName: standard_2.standard_set.display_name
          }
        ]
      }
    end

    let(:matching_assets) do
      [
        {
          standard_asset_id: standard_asset_1.id,
          reference_type: standard_asset_1.reference_type,
          reference_id: standard_asset_1.reference_id
        },
        {
          standard_asset_id: standard_asset_2.id,
          reference_type: standard_asset_2.reference_type,
          reference_id: standard_asset_2.reference_id
        },
        {
          standard_asset_id: standard_asset_3.id,
          reference_type: standard_asset_3.reference_type,
          reference_id: standard_asset_3.reference_id
        },
        {
          standard_asset_id: standard_asset_4.id,
          reference_type: standard_asset_4.reference_type,
          reference_id: standard_asset_4.reference_id
        }
      ]
    end

    let(:te_item_ids) { [ereader_item.id] }
    let(:vtext_linker) { double('VTextLinker', link: 'http://example.com') }
    let(:assignment_validator) { instance_double(AssignmentValidator) }

    let(:alignment_item_sorter) do
      described_class.new(
        cms_activity_ids,
        grouped_standard_alignments,
        matching_assets,
        program,
        standards_course.sections,
        te_item_ids,
        vtext_linker,
        assignment_validator
      )
    end

    describe '#process' do
      it 'processes unit lesson concept hash correctly' do
        allow(assignment_validator)
          .to receive(:unassignable_reason)
          .and_return('test')

        unit_lesson_concept_hash = Hash.new do |unit_hash, unit_key|
          unit_hash[unit_key] = Hash.new do |lesson_hash, lesson_key|
            lesson_hash[lesson_key] = Hash.new do |concept_hash, concept_key|
              concept_hash[concept_key] = []
            end
          end
        end

        processed_hash = alignment_item_sorter.process(unit_lesson_concept_hash)

        unit_lesson_concept_hash.each_key do |unit_id|
          unit_lesson_concept_hash[unit_id].each_key do |lesson_id|
            unit_lesson_concept_hash[unit_id][lesson_id].each_key do |concept_id|
              program.lessons do |my_lesson|
                expect(processed_hash[unit_id][lesson_id][concept_id][0][:unitId])
                  .to eq(my_lesson.unit.id)

                expect(processed_hash[unit_id][lesson_id][concept_id][0][:lessonId])
                  .to eq(my_lesson.id)
              end
            end
          end
        end
      end
    end

    describe '#activities_and_alignments' do
      it 'returns array of aligned asset data in the correct order' do
        create(:assignment, assignable: activity_1, section: standards_course.sections.first)
        activity_2.update!(lesson: program.lessons.first)
        aligned_assets = alignment_item_sorter.activities_and_alignments
        expect(aligned_assets[0][:activity].id).to eq(activity_2.id)
        expect(aligned_assets[1][:activity].id).to eq(exam.id)
        expect(aligned_assets[2][:activity].id).to eq(activity_1.id)
        expect(aligned_assets[3][:activity].id).to eq(ereader_item.id)
      end
    end
  end

  describe '#initialize' do
    include_context 'with standards_course'
    context 'with a nil value for standards_ids_for_init' do
      it 'sets @standard_guids_for_init to an empty array' do
        presenter = described_class.new(program, course)
        expect(presenter.standard_guids_for_init).to eq([])
      end
    end

    context 'with a value that does not map to an m3 Standard' do
      it 'sets @standard_guids_for_init to contain an error flag' do
        presenter = described_class.new(program, standards_course, standard_ids_for_init: 'foo')
        expect(
          presenter.standard_guids_for_init
        ).to eq(['error'])
      end
    end

    context 'with a comma separated string of m3 standard ids for standards_ids_for_init' do
      it 'sets @standard_guids_for_init to an array of vendor guids' do
        standard_1 = create(:standard)
        standard_2 = create(:standard)

        presenter = described_class.new(
          program, standards_course, standard_ids_for_init: "#{standard_1.id}, #{standard_2.id}"
        )
        expect(
          presenter.standard_guids_for_init
        ).to eq([standard_1.vendor_guid, standard_2.vendor_guid])
      end
    end
  end
end
