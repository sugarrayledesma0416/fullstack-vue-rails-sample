class FaultyImageDimensionsTest
  include ImageDimensions

  attr_accessor :file_path

  def initialize(file_path)
    self.file_path = file_path
  end

  def save_image
    set_dimensions
  end

  def update_column; end
end

class ImageDimensionsTest < FaultyImageDimensionsTest
  def image_file_path
    file_path
  end
end

describe ImageDimensions do
  let(:width) { 100 }
  let(:height) { 200 }
  let(:magick_mock) do
    object_double(
      MiniMagick::Image.new('blah'),
      dimensions: [width, height]
    )
  end

  before do
    allow(MiniMagick::Image).to receive(:open).and_return(magick_mock)
  end

  describe '#save_image' do
    it 'raises NotImplementedError if image_file_path method is not implemented' do
      expect do
        FaultyImageDimensionsTest.new('some/nice/path').save_image
      end.to raise_error(NotImplementedError)
    end

    context 'when image file does not exist' do
      it 'does not try to set any attributes' do
        image_object = ImageDimensionsTest.new(nil)
        allow(image_object).to receive(:update_column)
        image_object.save_image
        expect(image_object).not_to have_received(:update_column)
      end
    end

    context 'when image file exists' do
      let(:original_path) { 'some/nice/path' }
      let(:image_object) { ImageDimensionsTest.new(original_path) }

      before { allow(image_object).to receive(:update_column) }

      it 'reads the image specified by the file path' do
        image_object.save_image
        expect(MiniMagick::Image).to have_received(:open)
          .with(original_path)
      end

      it 'url-encodes spaces in the image file path' do
        image_object.file_path = 'path with spaces'
        image_object.save_image
        expect(MiniMagick::Image).to have_received(:open)
          .with('path%20with%20spaces')
      end

      it 'updates the width column of the record with the width of the image' do
        image_object.save_image
        expect(image_object).to have_received(:update_column)
          .with(:width, width)
      end

      it 'updates the height column of the record with the height of the image' do
        image_object.save_image
        expect(image_object).to have_received(:update_column)
          .with(:height, height)
      end
    end
  end
end
