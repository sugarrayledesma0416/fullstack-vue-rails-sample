describe NoWrapFlashHelper do
  describe '#no_wrap_class_for_flash' do
    before do
      allow(helper).to receive(:controller_name).and_return(current_controller)
    end

    context 'when the controller is in CONTROLLERS_WITH_NO_WRAP' do
      let(:current_controller) { 'created_activities' }

      it 'returns "u-txt-nowrap"' do
        expect(helper.no_wrap_class_for_flash).to eq('u-txt-nowrap')
      end
    end

    context 'when the controller is not in CONTROLLERS_WITH_NO_WRAP' do
      let(:current_controller) { 'other_controller' }

      it 'returns an empty string' do
        expect(helper.no_wrap_class_for_flash).to eq('')
      end
    end
  end
end
