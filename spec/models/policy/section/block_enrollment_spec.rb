describe Policy::Section::BlockEnrollment do
  let(:instructor) { build_stubbed(:instructor) }
  let(:course) { build_stubbed(:course) }
  let(:section) { build_stubbed(:section, course: course) }
  let(:policy) { described_class.new(instructor, section) }
  describe '#permit?' do
    context 'when user is not Clever' do
      context 'when user is the owner of the section' do
        it 'permits blocking the section from enrollments' do
          allow(section).to receive(:instructor) { instructor }
          expect(policy.permit?).to be_truthy
        end
      end

      context 'when user is the owner of the section course' do
        it 'permits blocking the section from enrollments' do
          allow(course).to receive(:owner) { instructor }
          expect(policy.permit?).to be_truthy
        end
      end

      context 'when user is neither the owner of the section nor the course' do
        it 'does not permit blocking the section from enrollments' do
          expect(policy.permit?).to be_falsey
        end
      end
    end

    context 'when user is Clever' do
      it 'does not permit blocking the section from enrollments' do
        allow(instructor).to receive(:clever?) { true }
        expect(policy.permit?).to be_falsey
      end
    end
  end

  describe '#can?' do
    context 'when user is Clever' do
      it 'returns false' do
        allow(instructor).to receive(:clever?) { true }
        expect(policy.can?).to be_falsey
      end
    end

    context 'when user is not Clever' do
      it 'returns true' do
        allow(instructor).to receive(:clever?) { false }
        expect(policy.can?).to be_truthy
      end
    end

    context 'when user is One Roster' do
      it 'returns false' do
        allow(instructor).to receive(:one_roster?) { true }
        expect(policy.can?).to be_falsey
      end
    end

    context 'when user is not One Roster' do
      it 'returns true' do
        allow(instructor).to receive(:one_roster?) { false }
        expect(policy.can?).to be_truthy
      end
    end

    context 'when user is LTI-A Rostering' do
      it 'returns false' do
        allow(instructor).to receive(:lti_rostering?) { true }
        expect(policy.can?).to be_falsey
      end
    end

    context 'when user is not Lti-A Rostering' do
      it 'returns true' do
        allow(instructor).to receive(:lti_rostering?) { false }
        expect(policy.can?).to be_truthy
      end
    end

  end
end
