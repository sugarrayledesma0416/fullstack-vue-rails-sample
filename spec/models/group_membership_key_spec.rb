describe GroupMembershipKey do
  describe '#key' do
    let(:course) { create(:course) }
    # this is the hash of 1,1,2,3 (user_id and three section ids)
    let(:expected) do
      '9b5ad156d9f07fb0a68737f63c0cb159c9440695be30384ab6e8449938ccf870'
    end

    def ensure_user(target_type, id)
      # This is needed so that the user ids can be harcoded. Otherwise
      # the only ways to test the code would be to write specs that stub
      # expect Digest::SHA256.to receive(:hexdigest) with key_material
      # computed by duplicating the key_material method of the class on the
      # Factory-assigned ids, or by duplicating all of the class logic to
      # calculate an expected hash.
      # Without this, the specs can fail with Mysql2::Error:
      #   Duplicate entry '1' for key 'PRIMARY': INSERT INTO `users`...
      user = User.find_by(id: id)
      if user
        return user if user.account_type.downcase == target_type.to_s

        user.delete
      end
      create(target_type, id: id)
    end

    before do
      [1, 2, 3, 4].each do |id|
        create(
          :section_without_section_instructor_callback,
          course: course,
          id: id
        )
      end
    end

    context 'with an instructor,' do
      let(:instructor) { ensure_user(:instructor, 1) }

      it 'returns a SHA256 hash of their user id + unarchived sections as a hex string' do
        [3, 1, 2].each do |id|
          create(:section_instructor, instructor: instructor, section_id: id)
        end

        # This section should be ignored.
        create(
          :section_instructor,
          instructor: instructor,
          is_archived: true,
          section_id: 4
        )

        expect(described_class.new(instructor).key).to eq(expected)
      end
    end

    context 'with a student,' do
      let(:student) { ensure_user(:student, 1) }

      it "returns a SHA256 hash of the student's enrolled sections as a hex string" do
        [3, 1, 2].each do |id|
          create(:enrollment, section_id: id, user: student)
        end

        # These should be ignored
        %w[transferred dropped marked_complete].each do |state|
          create(:enrollment, section_id: 4, state: state, user_id: student.id)
        end

        expect(described_class.new(student).key).to eq(expected)
      end
    end
  end
end
