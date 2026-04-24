describe TrackGroup do
  describe ".scopes" do
    describe ".names_by_program" do
      let(:program) { create(:program) }
      let(:other_program) { create(:program) }

      it "returns uniq names" do
        track_group_1 = create(:track_group, :program => program, :name => 'one')
        track_group_2 = create(:track_group, :program => program, :name => 'one')

        expect(TrackGroup.names_by_program(program)).to eql(['one'])
      end

      it "returns names for the given program" do
        track_group_1 = create(:track_group, :program => program, :name => 'one')
        track_group_2 = create(:track_group, :program => other_program, :name => 'two')

        expect(TrackGroup.names_by_program(program)).to eql(['one'])

      end
    end
  end
end
