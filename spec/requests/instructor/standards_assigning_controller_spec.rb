require 'requests/login_helper_methods'

describe Instructor::StandardsAssigningController do
  let(:standards_program) { create(:program) }
  let(:non_standards_program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:standard_set) { create(:standard_set) }
  let(:school) { create(:school) }
  let!(:program_config) do
    create(
      :program_config_with_standard_sets,
      program: standards_program,
      supported_standard_sets: [standard_set]
    )
  end
  let(:course) do
    create(
      :open_course,
      school:,
      owner: instructor,
      program: standards_program,
      standard_sets: [standard_set]
    )
  end
  let(:standards_course) do
    create(
      :open_course,
      owner: instructor,
      program: standards_program,
      standard_set_ids: [standard_set.id]
    )
  end
  let(:standards_section) do
    create(
      :section,
      course: standards_course,
      instructor:
    )
  end

  # Test setup for good Open Search responses
  shared_context 'with successful OS responses' do
    before do
      presenter = instance_double(StandardsAssigningPresenter)
      allow(StandardsAssigningPresenter).to receive(:new).and_return(presenter)
      allow(presenter).to receive(:assets_and_standards_payload).and_return({ foo: 'bar' })
      allow(presenter).to receive(:matching_standards).and_return({ foo: 'bar' })
      allow(presenter).to receive(:assignment_validator=)
      allow(presenter).to receive(:vtext_linker=)
      allow(presenter).to receive(:browse_standards).and_return({ foo: 'bar' })
    end
  end

  # Test setup for Open Search responses with errors
  shared_context 'with unsuccessful OS responses' do
    before do
      presenter = instance_double(StandardsAssigningPresenter)
      allow(StandardsAssigningPresenter).to receive(:new).and_return(presenter)
      allow(presenter)
        .to receive(:assets_and_standards_payload).and_raise(StandardError, 'error msg')
      allow(presenter).to receive(:matching_standards).and_raise(StandardError, 'error msg')
      allow(presenter).to receive(:assignment_validator=)
      allow(presenter).to receive(:vtext_linker=)
      allow(presenter).to receive(:browse_standards).and_raise(StandardError, 'error msg')
    end
  end

  context 'with a standards configured program' do
    let(:presenter) { instance_double(StandardsAssigningPresenter) }

    before do
      log_in_user_with_access_to_programs(instructor, [standards_program])
      allow(presenter).to receive(:assignment_validator=)
      allow(presenter).to receive(:vtext_linker=)
      allow(presenter).to receive(:preload_standards_filter)
      allow(presenter).to receive(:available_sets)
      allow(presenter).to receive(:current_program).and_return(standards_program)
      allow(presenter).to receive(:current_course).and_return(standards_course)
      allow(presenter).to receive(:program_toc_type).and_return('unit')
      allow(presenter).to receive(:standard_guids_for_init).and_return(nil)
      allow(presenter).to receive(:available_browse_std_sets).and_return([standard_set])
      allow(presenter).to receive(:available_grades_for_browse).and_return({ display_grade: 'grade 6', grade: 'grade 6' })
      allow(presenter).to receive(:toc)
      allow(StandardsAssigningPresenter).to receive(:new).and_return(presenter)
      allow(described_class).to receive(:current_focus).and_return(double('Focus',
                                                                          course: standards_course,
                                                                          section: standards_section))
    end

    describe 'GET :index' do
      it 'returns the index view' do
        allow(presenter).to receive(:standard_guids_for_init).and_return({})
        allow(presenter).to receive(:error_msg).and_return(nil)
        get(instructor_standards_assigning_path(standards_program.id))
        expect(response).to be_ok
      end

      context 'with a standard param' do
        it 'shows a flash message if no matching standards were found' do
          allow(presenter).to receive(:preload_standards_filter).and_raise(StandardError, 'error msg')
          allow(presenter).to receive(:error_msg).and_return('No matching standards found.')
          get("#{instructor_standards_assigning_path(standards_program.id)}?standards=blah")
          expect(flash[:error]).to eq('No matching standards found.')
        end

        it 'does not show a flash message if the standard was found' do
          allow(presenter).to receive(:error_msg).and_return(nil)
          standard = create(:standard, standard_set:)
          get(
            "#{instructor_standards_assigning_path(standards_program.id)}" \
            "?standards=#{standard.id}"
          )
          expect(flash[:error]).to be_nil
        end
      end
    end

    describe 'GET :data_for_assigned_item' do
      let(:assignment) { create(:assignment, section: standards_section) }
      let(:assignments_relation) { double('ActiveRecord::Relation', where: [assignment]) }
      let(:presenter) { instance_double(StandardsAssigningPresenter) }
      let(:activity_assigned_1) { create(:activity) }
      let(:activity_assigned_2) { create(:activity) }
      let(:standard_set_1) { create(:standard_set, display_name: 'dn 1') }
      let(:standard_set_2) { create(:standard_set, display_name: 'dn 2') }
      let(:standard_asset_1) do
        create(:standard_asset, reference_id: activity_assigned_1.cms_activity_id)
      end
      let(:standard_asset_2) do
        create(:standard_asset, reference_id: activity_assigned_2.cms_activity_id)
      end
      let(:item) do
        {
          activityId: activity_assigned_1.id,
          activityTitle: activity_assigned_1.title,
          assessmentAvailability: 'available',
          assignmentsDueDate: {},
          assignmentIds: assignment.id.to_s,
          referenceType: 'AssessmentItem',
          releaseLinkText: 'Release Link Text',
          activityUrl: 'activity_url',
          activityIcons: 'formatted_icon',
          te_descriptor: nil,
          unassignableReason: nil,
          hoverText: 'Hover Text',
          isAssignable: true,
          isExam: false,
          isIndividuallyAssigned: false,
          pageNumber: nil,
          pageSection: nil,
          unitId: activity_assigned_1.lesson.unit.id,
          lessonId: activity_assigned_1.lesson_id,
          showReleaseLink: false,
          standardAlignments: 'formatted_alignments',
          standardAssetIds: [standard_asset_1.id.to_s],
          strand_color: activity_assigned_1.concept.background_color
        }
      end

      let(:standard_1) do
        create(:standard, vendor_standard_set_guid: standard_set_1.vendor_guid)
      end
      let(:standard_2) do
        create(:standard, vendor_standard_set_guid: standard_set_2.vendor_guid)
      end

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
          ]
        }
      end

      before do
        allow(StandardsAssigningPresenter).to receive(:new).and_return(presenter)
        allow(Activity).to receive(:find).and_return(activity_assigned_1)
        allow(presenter).to receive(:assignments_by_activity)
          .and_return({ activity_assigned_1.id => [assignment] })
        allow(presenter).to receive(:item).and_return(item)
        allow(presenter).to receive(:assignment_validator=).and_return(true)
        allow(presenter).to receive(:vtext_linker=).and_return(true)
        allow(presenter).to receive(:fetch_alignments)
          .with([standard_asset_1.id], standards_course.standard_sets.pluck(:vendor_guid).uniq)
          .and_return(standard_alignment_1)
        allow(presenter).to receive(:grouped_alignments).and_return(grouped_standard_alignments)
      end

      it 'returns data for assigned item as json' do
        parsed_item = JSON.parse(item.to_json)
        post(
          instructor_data_for_assigned_item_path(standards_program.id, id: activity_assigned_1.id),
          params: {
            standard_asset_ids: [standard_asset_1.id],
            standard_set_guids: standards_course.standard_sets.pluck(:vendor_guid).uniq
          }
        )
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['data_for_assigned_item']).to eq(parsed_item)
      end
    end

    describe 'PUT :search_assets' do
      context 'with a successful result from OpenSearch' do
        include_context 'with successful OS responses'
        it 'returns asset json' do
          put(
            instructor_search_standard_assets_path(standards_program.id),
            params: { selected_standards: ['roo'] },
            as: :json
          )
          expect(response.parsed_body['assets_and_standards']).to eq({ 'foo' => 'bar' })
        end

        it 'returns a 400 if required params are missing' do
          put(instructor_search_standard_assets_path(standards_program.id), params: {}, as: :json)
          expect(response).to be_bad_request
        end
      end

      context 'with an unsuccesful result from OpenSearch' do
        include_context 'with unsuccessful OS responses'
        it 'returns an error status' do
          put(
            instructor_search_standard_assets_path(standards_program.id),
            params: { selected_standards: ['roo'] },
            as: :json
          )
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end

    describe 'PUT :search_standards' do
      context 'with a successful result from OpenSearch' do
        include_context 'with successful OS responses'

        it 'returns standard json' do
          put(
            instructor_search_standards_path(standards_program.id),
            params: { standard_set_vendor_guid: 'zoo', search_term: 'moo' },
            as: :json
          )
          expect(response.parsed_body['matched_standards']).to eq({ 'foo' => 'bar' })
        end

        it 'returns a 400 if required params are missing' do
          put(instructor_search_standards_path(standards_program.id), params: {}, as: :json)
          expect(response).to be_bad_request
        end
      end

      context 'with an unsuccesful result from OpenSearch' do
        include_context 'with unsuccessful OS responses'
        it 'returns an error status' do
          put(
            instructor_search_standards_path(standards_program.id),
            params: { standard_set_vendor_guid: 'zoo', search_term: 'moo' },
            as: :json
          )

          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end

    describe 'GET :browse_standards' do
      context 'with a successful result from OpenSearch' do
        include_context 'with successful OS responses'

        it 'returns standard json' do
          get(
            "#{instructor_browse_standards_path(standards_program.id)}?standard_set_vendor_guid=zoo",
            as: :json
          )
          expect(response.parsed_body['matched_browse_standards']).to eq({ 'foo' => 'bar' })
        end

        it 'returns a 400 if required params are missing' do
            get(instructor_browse_standards_path(standards_program.id), as: :json)
          expect(response).to be_bad_request
        end
      end

      context 'with an unsuccesful result from OpenSearch' do
        include_context 'with unsuccessful OS responses'
        it 'returns an error status' do
          get(
            "#{instructor_browse_standards_path(standards_program.id)}?standard_set_vendor_guid=zoo",
            as: :json
            )
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end
  end

  context 'with a program not configured for standards' do
    before do
      log_in_user_with_access_to_programs(instructor, [non_standards_program])
      allow(described_class).to receive(:current_focus).and_return(double('Focus',
                                                                          course: standards_course,
                                                                          section: standards_section))
    end

    describe 'GET :index' do
      it 'returns not authorized' do
        get(instructor_standards_assigning_path(non_standards_program.id))
        expect(response).to be_unauthorized
      end
    end

    describe 'PUT :search_assets' do
      it 'returns not authorized' do
        put(
          instructor_search_standard_assets_path(non_standards_program.id),
          params: { selected_standards: ['roo'] },
          as: :json
        )
        expect(response).to be_unauthorized
      end
    end

    describe 'PUT :search_standards' do
      it 'returns not authorized' do
        put(
          instructor_search_standards_path(non_standards_program.id),
          params: { standard_set_display_name: 'zoo', search_term: 'moo' },
          as: :json
        )
        expect(response).to be_unauthorized
      end
    end
  end
end
