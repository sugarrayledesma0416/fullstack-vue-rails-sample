describe ActivityIconsFormatter do
  describe '#format_activity_icons' do
    context 'with non-vol program family' do
      context 'with non-instructor graded' do
        context 'with a nil icon string' do
          it 'returns an empty string' do
            formatter = Class.new.extend(described_class)
            expect(
              formatter.format_activity_icons(nil, false, false)
            ).to eq([])
          end
        end

        it 'returns textbook icon as-is & does not add an apple' do
          icon_str = 'microphone,textbook'
          formatter = Class.new.extend(described_class)
          expect(
            formatter.format_activity_icons(icon_str, false, false)
          ).to eq(%w[microphone textbook])
        end
      end

      context 'with instructor graded' do
        it 'returns textbook icon as-is & does add an apple' do
          icon_str = 'microphone,textbook'
          formatter = Class.new.extend(described_class)
          expect(
            formatter.format_activity_icons(icon_str, false, true)
          ).to eq(%w[microphone textbook apple])
        end

        context 'with a nil icon string' do
          it 'returns an empty string' do
            formatter = Class.new.extend(described_class)
            expect(
              formatter.format_activity_icons(nil, false, true)
            ).to eq(%w[apple])
          end
        end
      end
    end

    context 'with vol-program-family' do
      context 'with non-instructor graded' do
        it 'returns textbook icon prefixed with vol_' do
          icon_str = 'microphone,textbook'
          formatter = Class.new.extend(described_class)
          expect(
            formatter.format_activity_icons(icon_str, true, false)
          ).to eq(%w[microphone vol_textbook])
        end
      end

      context 'with instructor graded' do
        it 'returns textbook icon prefixed with vol_' do
          icon_str = 'microphone,textbook'
          formatter = Class.new.extend(described_class)
          expect(
            formatter.format_activity_icons(icon_str, true, true)
          ).to eq(%w[microphone vol_textbook apple])
        end
      end
    end
  end
end
