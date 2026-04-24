describe InstructorHelpRequestsPresenter do
  let(:program) { build_stubbed(:program) }
  let(:activity) { build_stubbed(:activity) }
  let(:section) { build_stubbed(:section, :course => course) }
  let(:course) { build_stubbed(:course) }
  let(:focus) { double('Focus', :sections => [section], :course => course) }
  let(:student) { build_stubbed(:student) }
  let(:presenter) { InstructorHelpRequestsPresenter.new([section], [student]) }
  let(:help_request) { build_stubbed(:help_request, :user => student, :activity => activity) }
  let(:unprocessed_help_request_list) { double(InstructorHelpRequestsPresenter::ConceptGroupList, :<< => true, :concept_groups => []) }
  let(:processed_help_request_list) { double(InstructorHelpRequestsPresenter::ConceptGroupList, :<< => true, :concept_groups => []) }
  let(:unprocessed_review_request_list) { double(InstructorHelpRequestsPresenter::ConceptGroupList, :<< => true, :concept_groups => []) }
  let(:processed_review_request_list) { double(InstructorHelpRequestsPresenter::ConceptGroupList, :<< => true, :concept_groups => []) }
  let(:scope) { double('scope') }

  describe 'the base presenter' do
    before do
      allow(HelpRequest).to receive(:instructor_respondable_by_user_and_section).and_return(scope)
      allow(scope).to receive(:include_location).and_return([help_request])
      allow(InstructorHelpRequestsPresenter::ConceptGroupList).to receive(:new).and_return(processed_help_request_list, unprocessed_help_request_list,
      processed_review_request_list, unprocessed_review_request_list)
    end

    describe '#populate' do
      it 'finds review requests for the specified sections' do
        expect(HelpRequest).to receive(:instructor_respondable_by_user_and_section).with([student], [section]).and_return(scope)
        expect(scope).to receive(:include_location).and_return([help_request])
        presenter.populate
      end

      it 'returns self to allow method-chaining' do
        expect(presenter.populate).to eq(presenter)
      end

      context 'with an unprocessed help request' do
        it 'adds the request to the unprocessed help request list' do
          allow(help_request).to receive(:request_type).and_return('request_help')
          allow(help_request).to receive(:processed?).and_return(false)

          expect(unprocessed_help_request_list).to receive(:<<).with(help_request)

          presenter.populate
        end
      end

      context 'with a processed help request' do
        it 'adds the request to the processed help request list' do
          allow(help_request).to receive(:request_type).and_return('request_help')
          allow(help_request).to receive(:processed?).and_return(true)

          expect(processed_help_request_list).to receive(:<<).with(help_request)

          presenter.populate
        end
      end

      context 'with an unprocessed review request' do
        it 'adds the request to the unprocessed review request list' do
          allow(help_request).to receive(:request_type).and_return('request_review')
          allow(help_request).to receive(:processed?).and_return(false)

          expect(unprocessed_review_request_list).to receive(:<<).with(help_request)

          presenter.populate
        end
      end

      context 'with a processed review request' do
        it 'adds the request to the processed review request list' do
          allow(help_request).to receive(:request_type).and_return('request_review')
          allow(help_request).to receive(:processed?).and_return(true)

          expect(processed_review_request_list).to receive(:<<).with(help_request)

          presenter.populate
        end
      end
    end

    describe '#request_count_for' do
      it 'returns the request count for the specified list' do
        allow(processed_help_request_list).to receive(:request_count).and_return(1)
        allow(unprocessed_help_request_list).to receive(:request_count).and_return(2)

        expect(presenter.request_count_for(:processed_help_requests)).to eq(1)
        expect(presenter.request_count_for(:unprocessed_help_requests)).to eq(2)
      end
    end

    describe '#concept_groups_for' do
      it 'returns the concept groups for the specified list' do
        allow(processed_help_request_list).to receive(:concept_groups).and_return(['a'])
        allow(unprocessed_help_request_list).to receive(:concept_groups).and_return(['b'])

        expect(presenter.concept_groups_for(:processed_help_requests)).to eq(['a'])
        expect(presenter.concept_groups_for(:unprocessed_help_requests)).to eq(['b'])
      end
    end
  end

  describe InstructorHelpRequestsPresenter::ConceptGroupList do
    let(:concept_group_list) { InstructorHelpRequestsPresenter::ConceptGroupList.new }

    let(:concept_1) { build_stubbed(:concept) }
    let(:concept_2) { build_stubbed(:concept) }

    let(:concept_1_group) { double('ConceptGroup', :id => concept_1.id, :<< => true) }
    let(:concept_2_group) { double('ConceptGroup', :id => concept_2.id, :<< => true) }

    let(:concept_1_help_request) { build_stubbed(:help_request).extend(InstructorHelpRequestsPresenter::PresentableRequest) }
    let(:concept_2_help_request) { build_stubbed(:help_request).extend(InstructorHelpRequestsPresenter::PresentableRequest) }

    describe '#<<' do
      before do
        allow(concept_1_help_request).to receive(:activity_concept).and_return(concept_1)
        allow(concept_2_help_request).to receive(:activity_concept).and_return(concept_2)
        allow(InstructorHelpRequestsPresenter::ConceptGroup).to receive(:new).and_return(concept_1_group)
      end

      context 'when no help requests have been added with the specified concept' do
        it 'initializes a new ConceptGroup with the help request concept and appends the help request to it' do
          expect(InstructorHelpRequestsPresenter::ConceptGroup).to receive(:new).with(concept_1).and_return(concept_1_group)
          expect(concept_1_group).to receive(:<<).with(concept_1_help_request)

          concept_group_list << concept_1_help_request
        end
      end

      context 'when help requests already exist with the specified concept' do
        before do
          concept_group_list.subgroups_by_id = {concept_1.id => concept_1_group, concept_2.id => concept_2_group}
        end

        it 'adds the specified help request to the concept group corresponding to the activity concept id' do

          expect(concept_1_group).to receive(:<<).with(concept_1_help_request)
          expect(concept_1_group).not_to receive(:<<).with(concept_2_help_request)
          expect(concept_2_group).to receive(:<<).with(concept_2_help_request)
          expect(concept_2_group).not_to receive(:<<).with(concept_1_help_request)

          concept_group_list << concept_1_help_request
          concept_group_list << concept_2_help_request
        end
      end

      it 'increments the request count' do
        expect{ concept_group_list << concept_1_help_request }.to change(concept_group_list, :request_count).by(1)
      end
    end

    describe '#concept_groups' do
      it 'returns the concept groups sorted by concept_combined_rank (lesson rank, then concept rank)' do
        allow(concept_1_group).to receive(:concept_combined_rank).and_return(2)
        allow(concept_2_group).to receive(:concept_combined_rank).and_return(1)
        concept_group_list.subgroups_by_id = {concept_1.id => concept_1_group, concept_2.id => concept_2_group}

        expect(concept_group_list.concept_groups).to eq([concept_2_group, concept_1_group])
      end
    end
  end

  describe InstructorHelpRequestsPresenter::ConceptGroup do
    let(:lesson) { build_stubbed(:lesson) }
    let(:concept) { build_stubbed(:concept, :lesson => lesson, :rank => 34) }

    let(:concept_group) { InstructorHelpRequestsPresenter::ConceptGroup.new(concept) }

    let(:activity_1) { build_stubbed(:activity) }
    let(:activity_2) { build_stubbed(:activity) }

    let(:activity_1_group) { double('ActivityGroup', :id => activity_1.id, :<< => true) }
    let(:activity_2_group) { double('ActivityGroup', :id => activity_2.id, :<< => true) }

    let(:activity_1_help_request) { build_stubbed(:help_request, :activity => activity_1).
                                      extend(InstructorHelpRequestsPresenter::PresentableRequest) }
    let(:activity_2_help_request) { build_stubbed(:help_request, :activity => activity_2).
                                      extend(InstructorHelpRequestsPresenter::PresentableRequest) }

    describe '#<<' do
      before do
        allow(InstructorHelpRequestsPresenter::ActivityGroup).to receive(:new).and_return(activity_1_group)
      end

      context 'when no help requests have been added with the specified activity' do
        it 'initializes a new ActivityGroup with the help request activity and appends the help request to it' do
          expect(InstructorHelpRequestsPresenter::ActivityGroup).to receive(:new).with(activity_1).and_return(activity_1_group)
          expect(activity_1_group).to receive(:<<).with(activity_1_help_request)

          concept_group << activity_1_help_request
        end
      end

      context 'when help requests already exist for this concept with the specified activity' do
        before do
          concept_group.subgroups_by_id = {activity_1.id => activity_1_group, activity_2.id => activity_2_group}
        end

        it 'adds the specified help request to the activity group corresponding to the activity id' do
          expect(activity_1_group).to receive(:<<).with(activity_1_help_request)
          expect(activity_1_group).not_to receive(:<<).with(activity_2_help_request)
          expect(activity_2_group).to receive(:<<).with(activity_2_help_request)
          expect(activity_2_group).not_to receive(:<<).with(activity_1_help_request)

          concept_group << activity_1_help_request
          concept_group << activity_2_help_request
        end
      end
    end

    describe '#concept_combined_rank' do
      it 'combines lesson combined rank with concept rank in lesson to faciliate sorting across lessons' do
        concept_group = InstructorHelpRequestsPresenter::ConceptGroup.new(concept)

        expect(concept_group.concept_combined_rank).to eq(134)
      end
    end

    describe '#activity_groups' do
      it 'returns the activity groups sorted by toc location rank' do
        allow(activity_1_group).to receive(:toc_location_rank).and_return(2)
        allow(activity_2_group).to receive(:toc_location_rank).and_return(1)
        concept_group.subgroups_by_id = {activity_1.id => activity_1_group, activity_2.id => activity_2_group}

        expect(concept_group.activity_groups).to eq([activity_2_group, activity_1_group])
      end
    end
  end

  describe InstructorHelpRequestsPresenter::ActivityGroup do
    let(:activity) { build_stubbed(:activity) }
    let(:activity_group) { InstructorHelpRequestsPresenter::ActivityGroup.new(activity) }

    let(:student_1) { build_stubbed(:student) }
    let(:student_2) { build_stubbed(:student) }

    let(:student_1_group) { double('StudentGroup', :id => student_1.id, :<< => true) }
    let(:student_2_group) { double('StudentGroup', :id => student_2.id, :<< => true) }

    let(:student_1_help_request) { build_stubbed(:help_request).extend(InstructorHelpRequestsPresenter::PresentableRequest) }
    let(:student_2_help_request) { build_stubbed(:help_request).extend(InstructorHelpRequestsPresenter::PresentableRequest) }

    describe '#<<' do
      before do
        student_1_help_request.student = student_1
        student_2_help_request.student = student_2
        allow(InstructorHelpRequestsPresenter::StudentGroup).to receive(:new).and_return(student_1_group)
      end

      context 'when no help requests have been added with the specified student' do
        it 'initializes a new StudentGroup with the help request student and appends the help request to it' do
          expect(InstructorHelpRequestsPresenter::StudentGroup).to receive(:new).with(student_1).and_return(student_1_group)
          expect(student_1_group).to receive(:<<).with(student_1_help_request)

          activity_group << student_1_help_request
        end
      end

      context 'when help requests already exist for this activity with the specified student' do
        before do
          activity_group.subgroups_by_id = {student_1.id => student_1_group, student_2.id => student_2_group}
        end

        it 'adds the specified help request to the student group corresponding to the student id' do
          expect(student_1_group).to receive(:<<).with(student_1_help_request)
          expect(student_1_group).not_to receive(:<<).with(student_2_help_request)
          expect(student_2_group).to receive(:<<).with(student_2_help_request)
          expect(student_2_group).not_to receive(:<<).with(student_1_help_request)

          activity_group << student_1_help_request
          activity_group << student_2_help_request
        end
      end
    end

    describe '#toc_location_rank' do
      context 'with an activity that has a toc_location_rank' do
        it 'returns the toc_location_rank of the activity' do
          toc_location_rank = 1234
          activity = build_stubbed(:activity, toc_location_rank: toc_location_rank)
          activity_group = InstructorHelpRequestsPresenter::ActivityGroup.new(activity)
          expect(activity_group.toc_location_rank).to eq(toc_location_rank)
        end
      end

      context 'with an activity with nil toc_location_rank' do
        # E.G. unlisted activities
        it 'returns an arbitrarily high rank' do
          activity = build_stubbed(:activity, toc_location_rank: nil)
          activity_group = InstructorHelpRequestsPresenter::ActivityGroup.new(activity)
          expect(activity_group.toc_location_rank).to eq(InstructorHelpRequestsPresenter::ActivityGroup::MAX_RANK)
        end
      end
    end

    describe '#student_groups' do
      it 'returns the student groups sorted by full name' do
        allow(student_1_group).to receive(:full_name).and_return('zzz')
        allow(student_2_group).to receive(:full_name).and_return('aaa')
        activity_group.subgroups_by_id = {student_1.id => student_1_group, student_2.id => student_2_group}

        expect(activity_group.student_groups).to eq([student_2_group, student_1_group])
      end
    end
  end

  describe InstructorHelpRequestsPresenter::StudentGroup do
    describe '#<<' do
      let(:section){ build_stubbed(:section) }
      let(:help_request){ build_stubbed(:help_request, :section => section) }
      let(:student){ build_stubbed(:student) }
      let(:student_group){ InstructorHelpRequestsPresenter::StudentGroup.new(student) }

      it 'increments the count of requests per student' do
        expect{ student_group << help_request }.to change(student_group, :count).by(1)
      end

      it 'sets section_id from help_request' do
        expect(student_group.section_id).to be_nil
        student_group << help_request
        expect(student_group.section_id).to eq(help_request.section_id)
      end

      it 'sets request_type from help_request' do
        expect(student_group.request_type).to be_nil
        student_group << help_request
        expect(student_group.request_type).to eq(help_request.request_type)
      end
    end
  end

  describe InstructorHelpRequestsPresenter::PresentableRequest do
    describe '#list_type' do
      let(:described_module) { InstructorHelpRequestsPresenter::PresentableRequest }

      context 'with a help request,' do
        it 'returns :processed_help_requests if the request is processed' do
          request = build_stubbed(:help_request, status: 'responded')
          request.extend(described_module)
          expect(request.list_type).to eq(:processed_help_requests)
        end

        it 'returns :unprocessed_help_requests if the request is not processed' do
          request = build_stubbed(:help_request, status: 'submitted')
          request.extend(described_module)
          expect(request.list_type).to eq(:unprocessed_help_requests)
        end
      end

      context 'with a score revew request,' do
        it 'returns :processed_review_requests if the request is processed' do
          request = build_stubbed(:review_request, status: 'responded')
          request.extend(described_module)
          expect(request.list_type).to eq(:processed_review_requests)
        end

        it 'returns :unprocessed_review_requests if the request is not processed' do
          request = build_stubbed(:review_request, status: 'submitted')
          request.extend(described_module)
          expect(request.list_type).to eq(:unprocessed_review_requests)
        end
      end
    end
  end
end
