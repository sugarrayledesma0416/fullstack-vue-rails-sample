describe PreviewMediaItem do
  let(:public_filename) { 'http://my/override' }
  let(:alt_tag) { 'my alt tag' }
  let(:preview_attrs) { {} }
  let(:desired_media_type) { '' }

  subject {
    described_class.new(preview_attrs: preview_attrs, desired_media_type: desired_media_type)
  }

  it 'is a read-only object' do
    expect { subject.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  describe '#height' do
    context 'when height is an empty string' do
      let(:preview_attrs) { { height: '' } }

      it { expect(subject.height).to be_nil }
    end

    context 'when height is nil' do
      let(:preview_attrs) { { height: '' } }

      it { expect(subject.height).to be_nil }
    end

    context 'when height is present' do
      let(:preview_attrs) { { height: '300' } }

      it { expect(subject.height).to eq(300) }
    end
  end

  describe '#width' do
    context 'when width is an empty string' do
      let(:preview_attrs) { { width: '' } }

      it { expect(subject.width).to be_nil }
    end

    context 'when width is nil' do
      let(:preview_attrs) { { width: '' } }

      it { expect(subject.width).to be_nil }
    end

    context 'when width is present' do
      let(:preview_attrs) { { width: '300' } }

      it { expect(subject.width).to eq(300) }
    end
  end

  shared_examples 'a public filename method' do |method|
    let(:preview_attrs) { { public_filename: public_filename } }

    it { expect(subject.send(method)).to eq(public_filename) }
  end

  describe '#public_filename' do
    it_behaves_like 'a public filename method', :public_filename
  end

  describe '#public_filename_for_arc' do
    it_behaves_like 'a public filename method', :public_filename_for_arc
  end

  describe '#public_url_for_arc' do
    it_behaves_like 'a public filename method', :public_url_for_arc
  end

  describe '#server_url' do
    it 'returns an empty string regardless of argument' do
      expect(subject.server_url('ignored')).to eq('')
    end
  end

  describe '#alt_tag' do
    let(:preview_attrs) { { alt_tag: alt_tag } }

    it { expect(subject.alt_tag).to eq(alt_tag) }
  end
end
