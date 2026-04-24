require 'rails_helper'

describe MaestroActivityEngine::ActivityContent::Reading::Reading do
  let(:reading_object) { described_class.new }
  let(:program) { create(:program) }
  let(:program_settings) { ProgramSettings.new(program) }

  describe '#production_url' do
    let(:student_dsl_reader_link) { '//reader.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2_vtext' }
    let(:student_dsl_reader3_link) { '//reader3.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2_vtext' }

    context 'when program settings for reader3 are used' do
      before do
        allow(program_settings).to receive(:vtext_link).and_return(student_dsl_reader3_link)
        allow(program_settings).to receive(:has_vtext_link?).and_return(true)
      end

      it 'tries to build an absolute URL from the COMPRO3_PRODUCTION_URL constant' do
        reading_object.url = '/test-path'

        expect(reading_object.production_url(program_settings)).to eq 'https://reader3.vhlcentral.com/test-path'
      end
    end

    context 'when program settings for reader3 are used' do
      before do
        allow(program_settings).to receive(:vtext_link).and_return(student_dsl_reader_link)
      end

      it 'tries to build an absolute URL from the COMPRO_PRODUCTION_URL constant when no program setting is sent in' do
        reading_object.url = '/test-path'

        expect(reading_object.production_url).to eq 'https://reader.vhlcentral.com/test-path'
      end

      it 'tries to build an absolute URL from the COMPRO_PRODUCTION_URL constant when vtext link does not go to reader3' do
        reading_object.url = '/test-path'

        expect(reading_object.production_url(program_settings)).to eq 'https://reader.vhlcentral.com/test-path'
      end
    end
  end
end
