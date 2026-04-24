describe Policy::Course::Delete do
  let(:instructor) { FactoryBot.build_stubbed(:instructor) }
  let(:another_instructor) { FactoryBot.build_stubbed(:instructor) }
  let(:course) { FactoryBot.build_stubbed(:course, owner: instructor) }
  let(:section) { FactoryBot.build_stubbed(:section) }
  let(:sections) { [section] }

  describe '#permit?' do
    context 'when the user is not the course owner' do
      context 'when course is not editable' do
        context 'when course has sections' do
          it 'returns false' do
            allow(course).to receive(:editable?) { false }
            policy = described_class.new(course, sections, another_instructor)
            expect(policy.permit?).to be_falsey
          end
        end
      end
    end

    context 'when the user is not the course owner' do
      context 'when course is not editable' do
        context 'when course has no sections' do
          it 'returns false' do
            allow(course).to receive(:editable?) { false }
            policy = described_class.new(course, [], another_instructor)
            expect(policy.permit?).to be_falsey
          end
        end
      end
    end

    context 'when the user is the course owner' do
      context 'when course is not editable' do
        context 'when course has sections' do
          it 'returns false' do
            allow(course).to receive(:editable?) { false }
            policy = described_class.new(course, sections, instructor)
            expect(policy.permit?).to be_falsey
          end
        end
      end
    end

    context 'when the user is not the course owner' do
      context 'when course is editable' do
        context 'when course has sections' do
          it 'returns false' do
            allow(course).to receive(:editable?) { true }
            policy = described_class.new(course, sections, another_instructor)
            expect(policy.permit?).to be_falsey
          end
        end
      end
    end

    context 'when the user is the course owner' do
      context 'when course is not editable' do
        context 'when course has no sections' do
          it 'returns false' do
            allow(course).to receive(:editable?) { false }
            policy = described_class.new(course, [], instructor)
            expect(policy.permit?).to be_falsey
          end
        end
      end
    end


    context 'when the user is not the course owner' do
      context 'when course is editable' do
        context 'when course has no sections' do
          it 'returns false' do
            allow(course).to receive(:editable?) { true }
            policy = described_class.new(course, [], another_instructor)
            expect(policy.permit?).to be_falsey
          end
        end
      end
    end

    context 'when the user is the course owner' do
      context 'when course is editable' do
        context 'when course has sections' do
          it 'returns false' do
            allow(course).to receive(:editable?) { true }
            policy = described_class.new(course, sections, instructor)
            expect(policy.permit?).to be_falsey
          end
        end
      end
    end

    context 'when the user is the course owner' do
      context 'when course is editable' do
        context 'when course has no sections' do
          it 'returns true' do
            allow(course).to receive(:editable?) { true }
            policy = described_class.new(course, [], instructor)
            expect(policy.permit?).to be_truthy
          end
        end
      end
    end
  end

  describe '#denied_message' do
    context 'when the user is not the course owner' do
      context 'when course is not editable' do
        context 'when course has sections' do
          it 'returns message explaining that course is closed' do
            allow(course).to receive(:editable?) { false }
            policy = described_class.new(course, sections, another_instructor)
            expect(policy.denied_message)
              .to eql('You cannot delete a closed course.')
          end
        end
      end
    end

    context 'when the user is not the course owner' do
      context 'when course is not editable' do
        context 'when course has no sections' do
          it 'returns message explaining that course is closed' do
            allow(course).to receive(:editable?) { false }
            policy = described_class.new(course, [], another_instructor)
            expect(policy.denied_message)
              .to eql('You cannot delete a closed course.')
          end
        end
      end
    end

    context 'when the user is the course owner' do
      context 'when course is not editable' do
        context 'when course has sections' do
          it 'returns message explaining that course is closed' do
            allow(course).to receive(:editable?) { false }
            policy = described_class.new(course, sections, instructor)
            expect(policy.denied_message)
              .to eql('You cannot delete a closed course.')
          end
        end
      end
    end

    context 'when the user is not the course owner' do
      context 'when course is editable' do
        context 'when course has sections' do
          it 'returns message explaining that user is not the course owner' do
            allow(course).to receive(:editable?) { true }
            policy = described_class.new(course, sections, another_instructor)
            expect(policy.denied_message)
              .to eql('You must be the course owner to delete a course.')
          end
        end
      end
    end

    context 'when the user is the course owner' do
      context 'when course is not editable' do
        context 'when course has no sections' do
          it 'returns message explaining that course is closed' do
            allow(course).to receive(:editable?) { false }
            policy = described_class.new(course, [], instructor)
            expect(policy.denied_message)
              .to eql('You cannot delete a closed course.')
          end
        end
      end
    end

    context 'when the user is not the course owner' do
      context 'when course is editable' do
        context 'when course has no sections' do
          it 'returns message explaining that user is not the course owner' do
            allow(course).to receive(:editable?) { true }
            policy = described_class.new(course, [], another_instructor)
            expect(policy.denied_message)
              .to eql('You must be the course owner to delete a course.')
          end
        end
      end
    end

    context 'when the user is the course owner' do
      context 'when course is editable' do
        context 'when course has sections' do
          it 'returns message explaining that course has sections' do
            allow(course).to receive(:editable?) { true }
            policy = described_class.new(course, sections, instructor)
            expect(policy.denied_message)
              .to eql('Courses with sections cannot be deleted. Delete all sections to enable course deletion.')
          end
        end
      end
    end

    context 'when the user is the course owner' do
      context 'when course is editable' do
        context 'when course has no sections' do
          it 'returns nil' do
            allow(course).to receive(:editable?) { true }
            policy = described_class.new(course, [], instructor)
            expect(policy.denied_message).to be_nil
          end
        end
      end
    end
  end
end
