describe AssignmentRankListUpdater, :core => true do
  let(:assignment_5) { create(:assignment) }
  let(:assignment_2) { create(:assignment) }
  let(:assignment_3) { create(:assignment) }
  let(:assignment_4) { create(:assignment) }
  let(:assignment_6) { create(:assignment) }
  let(:assignments) do
    [assignment_5, assignment_2, assignment_3, assignment_4, assignment_6]
  end
  let(:params) { { assignment_ids: [] } }
  let(:updater) { described_class.new(params) }

  def build_params(ranking_list)
    params[:ranks] = ranking_list
    assignments.each_with_index do |assignment, index|
      assignment.update!(rank: ranking_list[index])
      params[:assignment_ids] << assignment.id
    end
  end

  def ranks
    assignments.map(&:rank)
  end

  def reload_assignments
    assignments.each do |assignment|
      assignment.reload
    end
  end

  describe '#process' do
    context 'when there is an assignment ahead in the list but there is not an element behind' do
      context "and next element's rank is lower than current element's rank" do
        before do
          build_params(["5", "2", "3", "4", "6"])
          params[:activity_types] = ["instructor-created", "regular", "regular", "instructor-created", "instructor-created"]
        end

        it "sets current element rank to the next assignment rank in the list" do
          updater.process
          reload_assignments

          expect(ranks).to eq([2, 2, 3, 4, 5])
        end
      end

      context "when next element's rank is greater than current element's rank" do
        before do
          build_params(["2", "3", "4", "5", "6"])
          params[:activity_types] = ["instructor-created", "regular", "regular", "instructor-created", "instructor-created"]
        end

        it "does not update current element rank" do
          updater.process
          reload_assignments

          expect(ranks).to eq([2, 3, 4, 5, 6])
        end
      end
    end

    context 'when there is an assignment behind in the list' do
      context "when there is not a tie between previous and next element's rank" do
        before do
          build_params(["5", "2", "3", "7", "6"])
          params[:activity_types] = ["instructor-created", "regular", "regular", "instructor-created", "instructor-created"]
        end

        it "sets current element rank to the previous assignment rank in the list plus one" do
          updater.process
          reload_assignments

          expect(ranks).to eq([2, 2, 3, 4, 5])
        end
      end

      context "when there is a tie between previous and next element's rank" do
        context "when current element's rank is greater than next rank" do
          before do
            build_params(["5", "2", "7", "2", "6"])
            params[:activity_types] = ["instructor-created", "regular", "instructor-created", "regular", "instructor-created"]
          end

          it "sets current element rank to the next assignment rank in the list" do
            updater.process
            reload_assignments

            expect(ranks).to eq([2, 2, 2, 2, 3])
          end
        end
      end

      context "when current element's rank is lower than next rank" do
        before do
          build_params(["10", "9", "10", "11", "12"])
          params[:activity_types] = ["regular", "instructor-created", "regular", "regular", "regular"]
        end

        it "sets current element rank to the next assignment rank in the list" do
          updater.process
          reload_assignments

          expect(ranks).to eq([10, 10, 10, 11, 12])
        end
      end
    end

    context "when there is a tie between first and last element's rank in the list" do
      context "And next element's rank is greater" do
        before do
          build_params(["1", "8", "12", "13", "8"])
          params[:activity_types] = ["instructor-created", "regular", "regular", "regular", "instructor-created"]
        end

        it "does not update current element's rank" do
          updater.process
          reload_assignments

          expect(ranks).to eq([1, 8, 12, 13, 14])
        end
      end
    end

    context 'when current element is between 2 elements which rank is higher' do
      before do
        build_params(["1", "6", "8", "1", "11"])
        params[:activity_types] = ["instructor-created", "regular", "regular", "instructor-created", "regular"]
      end

      it 'grabs previous rank and add one' do
        updater.process
        reload_assignments

        expect(ranks).to eq([1, 6, 8, 9, 11])
      end
    end
  end

end
