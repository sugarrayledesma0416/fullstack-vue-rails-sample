module StandardsMapping
  module Etl
    describe 'StandardConverter' do
      let(:std_set) { create(:standard_set, display_name: 'SOME STD SET') }
      let(:parent_std) { create(:standard, standard_set: std_set) }
      let(:ancestor1_std) { create(:standard, standard_set: std_set) }
      let(:ancestor2_std) { create(:standard, standard_set: std_set) }
      let(:add_info) do
        JSON.generate({
                        additional_info:
                        {
                          ancestors: "#{ancestor1_std.vendor_guid},#{ancestor2_std.vendor_guid}",
                          grade_levels: '6,7',
                          parent_guid: parent_std.vendor_guid
                        }
                      })
      end
      let(:standard) { create(:standard, standard_set: std_set, additional_info: add_info) }
      let(:orphan_add_info) do
        JSON.generate({
                        additional_info:
                        {
                          ancestors: '',
                          grade_levels: '5,6',
                          parent: nil
                        }
                      })
      end
      let(:orphan_standard) { create(:standard,
                                standard_set: std_set,
                                additional_info: orphan_add_info) }
      let(:empty_add_info) do
        JSON.generate({})
      end
      let(:no_info_standard) { create(:standard,
                                 standard_set: std_set,
                                 additional_info: empty_add_info) }
      let(:converter) { StandardConverter.new }

      describe '#convert' do
        let(:expected_result) do
          {
            standard_id: standard.id,
            vendor_guid: standard.vendor_guid,
            label: standard.label,
            number: standard.number,
            name: standard.name,
            description: standard.description,
            vendor_standard_set_guid: standard.vendor_standard_set_guid,
            issuer: std_set.issuer,
            display_name: 'SOME STD SET',
            searchable: true,
            parent: {
              standard_id: parent_std.id,
              vendor_guid: parent_std.vendor_guid,
              label: parent_std.label,
              number: parent_std.number,
              name: parent_std.name,
              description: parent_std.description,
              issuer: parent_std.standard_set.issuer,
              display_name: parent_std.standard_set.display_name,
              vendor_standard_set_guid: parent_std.vendor_standard_set_guid
            },
            grade_levels:
              [
                { grade_level: '6' },
                { grade_level: '7' }
              ],
            ancestors:
              [
                { vendor_guid: ancestor1_std.vendor_guid },
                { vendor_guid: ancestor2_std.vendor_guid }
              ]
          }
        end

        let(:expected_orphan_result) do
          {
            standard_id: orphan_standard.id,
            vendor_guid: orphan_standard.vendor_guid,
            label: orphan_standard.label,
            number: orphan_standard.number,
            name: orphan_standard.name,
            description: orphan_standard.description,
            vendor_standard_set_guid: orphan_standard.vendor_standard_set_guid,
            issuer: std_set.issuer,
            display_name: 'SOME STD SET',
            searchable: true,
            parent: nil,
            grade_levels:
              [
                { grade_level: '5' },
                { grade_level: '6' }
              ],
            ancestors: []
          }
        end

        let(:expected_no_info_result) do
          {
            standard_id: no_info_standard.id,
            vendor_guid: no_info_standard.vendor_guid,
            label: no_info_standard.label,
            number: no_info_standard.number,
            name: no_info_standard.name,
            description: no_info_standard.description,
            vendor_standard_set_guid: no_info_standard.vendor_standard_set_guid,
            issuer: std_set.issuer,
            display_name: 'SOME STD SET',
            searchable: true,
            parent: nil,
            grade_levels: nil,
            ancestors: nil
          }
        end

        it 'converts the properties of a Standard' do
          expect(converter.convert(standard)).to eql expected_result
        end

        it 'converts the properties of a Standard with no ancestors or parent' do
          expect(converter.convert(orphan_standard)).to eql expected_orphan_result
        end

        it 'converts the properties of a Standard with an empty additional_info value' do
          expect(converter.convert(no_info_standard)).to eql expected_no_info_result
        end
      end
    end
  end
end
