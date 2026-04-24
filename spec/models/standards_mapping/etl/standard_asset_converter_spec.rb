module StandardsMapping
  module Etl
    describe 'StandardAssetConverter' do
      let(:activity) { create(:activity_with_program) }
      let(:additional_attrs) do
        {
          domain: 'Reading Comprehension',
          subdomain: 'Short Stories'
        }
      end
      let(:standard_asset) do
        create(:standard_asset, reference_id: activity.cms_activity_id,
                                additional_attrs:)
      end
      let(:parent_std) { create(:standard) }
      let(:ancestor_std) { create(:standard) }
      let(:add_info) do
        JSON.generate({
                        additional_info:
                        {
                          ancestors: ancestor_std.vendor_guid,
                          grade_levels: '6,7,8',
                          parent_guid: parent_std.vendor_guid
                        }
                      })
      end
      let(:standard) { create(:standard, additional_info: add_info) }
      let(:standard_alignment) do
        create(:standard_alignment,
               standard_asset:,
               vendor_standard_guid: standard.vendor_guid)
      end
      let(:sa_unknown) { create(:standard_asset, reference_type: 'BLAH') }
      let(:unknown_type_message) do
        "UNRECOGNIZED AND UNSUPPORTED REFERENCE TYPE #{sa_unknown.reference_type}"
      end
      let(:expected_result_1) do
        {
          standard_asset_id: standard_asset.id,
          reference_type: StandardAsset::ACTIVITY_REFERENCE,
          reference_id: standard_asset.reference_id,
          domain: standard_asset.additional_attrs[:domain],
          subdomain: standard_asset.additional_attrs[:subdomain],
          programs: [
            program_id: activity.lesson.program.id,
            lesson_id: activity.lesson.id,
            unit_id: activity.lesson.unit.id
          ],
          standard_alignments:
            [
              {
                alignment_id: standard_alignment.id,
                alignment_status: 'aligned',
                vendor_guid: standard.vendor_guid,
                label: standard.label,
                number: standard.number,
                name: standard.name,
                description: standard.description,
                vendor_standard_set_guid: standard.vendor_standard_set_guid,
                parent:
                  {
                    vendor_guid: parent_std.vendor_guid,
                    label: parent_std.label,
                    number: parent_std.number,
                    name: parent_std.name,
                    description: parent_std.description,
                    vendor_standard_set_guid: parent_std.vendor_standard_set_guid
                  },
                ancestors:
                [
                  {
                    vendor_guid: ancestor_std.vendor_guid,
                    label: ancestor_std.label,
                    number: ancestor_std.number,
                    name: ancestor_std.name,
                    description: ancestor_std.description,
                    vendor_standard_set_guid: ancestor_std.vendor_standard_set_guid
                  }
                ],
                grade_levels:
                [
                  { grade_level: '6' },
                  { grade_level: '7' },
                  { grade_level: '8' }
                ]
              }
            ]
        }
      end
      let!(:assessment) { create(:activity_with_program, activity_type: 'exam') }
      let(:ai_standard_asset) do
        StandardAsset.create(
          vendor_guid: 'a-guid',
          reference_type: 'AssessmentItem',
          additional_attrs: nil,
          assessment_item_attributes: {
            assessment_id: assessment.cms_activity_id,
            guid: 'abc123',
            points_possible: 50
          }
        )
      end
      let(:ai_standard_alignment) do
        create(:standard_alignment,
               standard_asset: ai_standard_asset,
               vendor_standard_guid: standard.vendor_guid)
      end
      let(:expected_result_2) do
        {
          standard_asset_id: ai_standard_asset.id,
          reference_type: StandardAsset::ASSESSMENT_ITEM_REFERENCE,
          reference_id: ai_standard_asset.reference_id,
          domain: ai_standard_asset.additional_attrs[:domain],
          subdomain: ai_standard_asset.additional_attrs[:subdomain],
          programs: [
            program_id: assessment.lesson.program.id,
            lesson_id: assessment.lesson.id,
            unit_id: assessment.lesson.unit.id
          ],
          standard_alignments:
            [
              {
                alignment_id: ai_standard_alignment.id,
                alignment_status: 'aligned',
                vendor_guid: standard.vendor_guid,
                label: standard.label,
                number: standard.number,
                name: standard.name,
                description: standard.description,
                vendor_standard_set_guid: standard.vendor_standard_set_guid,
                parent:
                  {
                    vendor_guid: parent_std.vendor_guid,
                    label: parent_std.label,
                    number: parent_std.number,
                    name: parent_std.name,
                    description: parent_std.description,
                    vendor_standard_set_guid: parent_std.vendor_standard_set_guid
                  },
                ancestors:
                  [
                    {
                      vendor_guid: ancestor_std.vendor_guid,
                      label: ancestor_std.label,
                      number: ancestor_std.number,
                      name: ancestor_std.name,
                      description: ancestor_std.description,
                      vendor_standard_set_guid: ancestor_std.vendor_standard_set_guid
                    }
                  ],
                grade_levels:
                  [
                    { grade_level: '6' },
                    { grade_level: '7' },
                    { grade_level: '8' }
                  ]
              }
            ]
        }
      end
      let(:concept) { create(:concept) }
      let(:ei_standard_asset) do
        StandardAsset.create(
          vendor_guid: SecureRandom.uuid,
          reference_type: 'EReaderItem',
          additional_attrs: "",
          ereader_item_attributes: {
            guid: 'ereader_item_guid',
            concept:,
            title: 'Some title',
            descriptor: 'Describes something',
            page_section: 'Explore',
            page_number: 50
          }
        )
      end
      let(:ei_standard_alignment) do
        create(:standard_alignment,
               standard_asset: ei_standard_asset,
               vendor_standard_guid: standard.vendor_guid)
      end
      let(:expected_result_3) do
        {
          standard_asset_id: ei_standard_asset.id,
          reference_type: StandardAsset::EREADER_ITEM_REFERENCE,
          reference_id: ei_standard_asset.reference_id,
          domain: ei_standard_asset.additional_attrs[:domain],
          subdomain: ei_standard_asset.additional_attrs[:subdomain],
          programs: [
            program_id: ei_standard_asset.ereader_item.concept.program.id,
            lesson_id: ei_standard_asset.ereader_item.concept.lesson.id,
            unit_id: ei_standard_asset.ereader_item.concept.lesson.unit.id
          ],
          standard_alignments:
            [
              {
                alignment_id: ei_standard_alignment.id,
                alignment_status: 'aligned',
                vendor_guid: standard.vendor_guid,
                label: standard.label,
                number: standard.number,
                name: standard.name,
                description: standard.description,
                vendor_standard_set_guid: standard.vendor_standard_set_guid,
                parent:
                  {
                    vendor_guid: parent_std.vendor_guid,
                    label: parent_std.label,
                    number: parent_std.number,
                    name: parent_std.name,
                    description: parent_std.description,
                    vendor_standard_set_guid: parent_std.vendor_standard_set_guid
                  },
                ancestors:
                  [
                    {
                      vendor_guid: ancestor_std.vendor_guid,
                      label: ancestor_std.label,
                      number: ancestor_std.number,
                      name: ancestor_std.name,
                      description: ancestor_std.description,
                      vendor_standard_set_guid: ancestor_std.vendor_standard_set_guid
                    }
                  ],
                grade_levels:
                  [
                    { grade_level: '6' },
                    { grade_level: '7' },
                    { grade_level: '8' }
                  ]
              }
            ]
        }
      end
      let(:standard_asset_with_bad_parent) do
        create(:standard_asset, reference_id: activity.cms_activity_id, additional_attrs: "")
      end
      let(:bad_parent_add_info) do
        JSON.generate({
                        additional_info:
                          {
                            ancestors: SecureRandom.uuid,
                            grade_levels: '6,7,8',
                            parent_guid: SecureRandom.uuid
                          }
                      })
      end
      let(:standard_with_bad_parent) { create(:standard, additional_info: bad_parent_add_info) }
      let(:bad_parent_standard_alignment) do
        create(:standard_alignment,
               standard_asset: standard_asset_with_bad_parent,
               vendor_standard_guid: standard_with_bad_parent.vendor_guid)
      end
      let(:expected_bad_parent_result) do
        {
          standard_asset_id: standard_asset_with_bad_parent.id,
          reference_type: StandardAsset::ACTIVITY_REFERENCE,
          reference_id: standard_asset_with_bad_parent.reference_id,
          domain: standard_asset_with_bad_parent.additional_attrs[:domain],
          subdomain: standard_asset_with_bad_parent.additional_attrs[:subdomain],
          programs: [
            program_id: activity.lesson.program.id,
            lesson_id: activity.lesson.id,
            unit_id: activity.lesson.unit.id
          ],
          standard_alignments:
            [
              {
                alignment_id: bad_parent_standard_alignment.id,
                alignment_status: 'aligned',
                vendor_guid: standard_with_bad_parent.vendor_guid,
                label: standard_with_bad_parent.label,
                number: standard_with_bad_parent.number,
                name: standard_with_bad_parent.name,
                description: standard_with_bad_parent.description,
                vendor_standard_set_guid: standard_with_bad_parent.vendor_standard_set_guid,
                parent: nil,
                ancestors: [nil],
                grade_levels:
                  [
                    { grade_level: '6' },
                    { grade_level: '7' },
                    { grade_level: '8' }
                  ]
              }
            ]
        }
      end
      let(:standard_asset_with_no_parent)  do
        create(:standard_asset, reference_id: activity.cms_activity_id)
      end
      let(:no_parent_add_info) do
        JSON.generate({
                        additional_info:
                          {
                            ancestors: '',
                            grade_levels: '6,7,8',
                            parent_guid: ''
                          }
                      })
      end
      let(:standard_with_no_parent) { create(:standard, additional_info: no_parent_add_info) }
      let(:no_parent_standard_alignment) do
        create(:standard_alignment,
               standard_asset: standard_asset_with_no_parent,
               vendor_standard_guid: standard_with_no_parent.vendor_guid)
      end
      let(:expected_no_parent_result) do
        {
          standard_asset_id: standard_asset_with_no_parent.id,
          reference_type: StandardAsset::ACTIVITY_REFERENCE,
          reference_id: standard_asset_with_no_parent.reference_id,
          domain: standard_asset_with_no_parent.additional_attrs[:domain],
          subdomain: standard_asset_with_no_parent.additional_attrs[:subdomain],
          programs: [
            program_id: activity.lesson.program.id,
            lesson_id: activity.lesson.id,
            unit_id: activity.lesson.unit.id
          ],
          standard_alignments:
            [
              {
                alignment_id: no_parent_standard_alignment.id,
                alignment_status: 'aligned',
                vendor_guid: standard_with_no_parent.vendor_guid,
                label: standard_with_no_parent.label,
                number: standard_with_no_parent.number,
                name: standard_with_no_parent.name,
                description: standard_with_no_parent.description,
                vendor_standard_set_guid: standard_with_no_parent.vendor_standard_set_guid,
                parent: nil,
                ancestors: nil,
                grade_levels:
                  [
                    { grade_level: '6' },
                    { grade_level: '7' },
                    { grade_level: '8' }
                  ]
              }
            ]
        }
      end
      let(:converter) { StandardAssetConverter.new }

      before do
        standard_asset.standard_alignments << standard_alignment
        ai_standard_asset.standard_alignments << ai_standard_alignment
        ei_standard_asset.standard_alignments << ei_standard_alignment
        standard_asset_with_bad_parent.standard_alignments << bad_parent_standard_alignment
        standard_asset_with_no_parent.standard_alignments << no_parent_standard_alignment
      end

      describe '#convert' do
        it 'converts the properties and alignments for a StandardAsset of type Activity' do
          expect(converter.convert(standard_asset)).to eql expected_result_1
        end

        it 'converts the properties and alignments for a StandardAsset of type AssessmentItem' do
          expect(converter.convert(ai_standard_asset)).to eql expected_result_2
        end

        it 'converts the properties and alignments for a StandardAsset of type EreaderItem' do
          expect(converter.convert(ei_standard_asset)).to eql expected_result_3
        end

        it 'does not convert StandardAsset of unrecognized type' do
          expect(converter.convert(sa_unknown)).to eql unknown_type_message
        end

        it 'ignores the parent and any ancestor that does not exist' do
          expect(converter.convert(standard_asset_with_bad_parent)).to eql expected_bad_parent_result
        end

        it 'ignores missing parent and ancestors' do
          expect(converter.convert(standard_asset_with_no_parent)).to eql expected_no_parent_result
        end
      end
    end
  end
end
