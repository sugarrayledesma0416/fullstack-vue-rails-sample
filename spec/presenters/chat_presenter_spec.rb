describe ChatPresenter do

  describe '#chat_course_id_or_undefined' do
    context 'when there is no course id' do
      it 'returns undefined' do
        permit = double(VhlChat::Permission, chat_course_id: nil)
        presenter = described_class.new(permit)
        expect(presenter.chat_course_id_or_undefined).to eq('undefined')
      end
    end

    context 'when there is a course id' do
      it 'returns the course id' do
        permit = double(VhlChat::Permission, chat_course_id: 4)
        presenter = described_class.new(permit)
        expect(presenter.chat_course_id_or_undefined).to eq(4)
      end
    end
  end
end
