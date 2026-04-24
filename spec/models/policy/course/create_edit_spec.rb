describe Policy::Course::CreateEdit do
  let(:policy) { described_class.new(user) }

  # usage: course_create_edit_policy.allowed_to_create_content_in_course?(current_focus)
  describe '#allowed_to_create_content_in_course?' do
    let(:course) { create(:course) }
    let(:other_user) { create(:instructor) }
    let(:section) { create(:section, course: course) }
    let(:user) { create(:instructor) }

    context 'when the user is the owner the current course focus' do
      it 'returns true' do
        course.owner = user
        expect(policy).to be_allowed_to_create_content_in_course(course)
      end
    end

    context 'when the user is not the owner of the current course focus' do
      let!(:section_instructor) do
        create(:section_instructor, user_id: user.id, section: section)
      end

      before do
        course.owner = other_user
      end

      context 'when the user is allowed to edit content ' \
        'for all sections in the current course focus' do
        it 'returns true' do
          expect(policy).to be_allowed_to_create_content_in_course(course)
        end
      end

      context 'when the user is not allowed to edit content ' \
        'for all sections in the current course focus' do
        it 'returns false' do
          section_instructor.allowed_to_edit_content = false
          section_instructor.save!
          expect(policy).not_to be_allowed_to_create_content_in_course(course)
        end
      end
    end
  end

  # usage: course_create_edit_policy.permit?(school)
  describe '#permit?' do
    let(:user) { build_stubbed(:instructor) }

    it 'is false for districts, regardless of Clever' do
      non_clever_district = build_stubbed(:district)

      expect(policy.permit?(non_clever_district)).to be(false)

      clever_district = build_stubbed(:district, clever_id: generate(:clever_id))
      expect(policy.permit?(clever_district)).to be(false)
    end

    context 'for non-district schools' do
      context 'when the school is Clever' do
        let(:school) { build_stubbed(:clever_school) }

        it 'returns false for a non-Clever user that has not transitioned from ' \
           'Clever to LTI with rostering' do
          allow(user).to receive_messages(
            clever?: false,
            lti_rostering_transitioned_from_clever?: false
          )

          expect(policy.permit?(school)).to be(false)
        end

        it 'returns true for a Clever user at a Clever school' do
          allow(user).to receive(:clever?).and_return(true)

          expect(policy.permit?(school)).to be(true)
        end

        it 'returns true for a non-Clever user that has transitioned from ' \
           'Clever to LTI with rostering' do
          allow(user).to receive_messages(
            clever?: false,
            lti_rostering_transitioned_from_clever?: true
          )

          expect(policy.permit?(school)).to be(true)
        end
      end

      context 'when the school is non-Clever' do
        let(:school) { build_stubbed(:school) } # clever_id is nil.

        it 'returns true for a non-Clever user' do
          allow(user).to receive(:clever?).and_return(false)

          expect(policy.permit?(school)).to be(true)
        end

        # See code comment regarding the reason for this case.
        it 'returns false for a Clever user' do
          allow(user).to receive(:clever?).and_return(true)

          expect(policy.permit?(school)).to be(false)
        end
      end
    end
  end
end
