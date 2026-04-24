describe Enumerable do
  describe '#all_same?' do
    context 'when all items in the enumerable are identical' do
      before do
        @enumerable = ['foo', 'foo', 'foo']
      end

      it 'returns true' do
        expect(@enumerable.all_same?).to be_truthy
      end
    end

    context 'when any of the items in the enumerable are different' do
      before do
        @enumerable = ['foo', 'bar', 'foo']
      end

      it 'returns false' do
        expect(@enumerable.all_same?).to be_falsey
      end
    end

    context 'when there are no items' do
      before do
        @enumerable = []
      end

      it 'returns true' do
        expect(@enumerable.all_same?).to be_truthy
      end
    end
  end

  describe '#vary?' do
    context 'when all items in the enumerable are identical' do
      before do
        @enumerable = ['foo', 'foo', 'foo']
      end

      it 'returns false' do
        expect(@enumerable.vary?).to be_falsey
      end
    end

    context 'when any of the items in the enumerable are different' do
      before do
        @enumerable = ['foo', 'bar', 'foo']
      end

      it 'returns true' do
        expect(@enumerable.vary?).to be_truthy
      end
    end

    context 'when there are no items' do
      before do
        @enumerable = []
      end

      it 'returns false' do
        expect(@enumerable.vary?).to be_falsey
      end
    end
  end

  describe "#have_different_values_for?" do
    before do
      @obj_1 = double('Anything', :foo => 'bar')
      @obj_2 = double('Anything', :foo => 'bar')
    end

    context 'when attribute given for enumerable item has the same value' do
      before do
        @obj_1 = double('Anything', :foo => 'bar')
        @obj_2 = double('Anything', :foo => 'bar')
      end

      it 'returns false' do
        expect([@obj_1, @obj_2].have_different_values_for?(:foo)).to be_falsey
      end
    end

    context 'when items have different values for given attribute' do
      before do
        @obj_1 = double('Anything', :foo => 'bar')
        @obj_2 = double('Anything', :foo => 'foo')
      end

      it 'returns true' do
        expect([@obj_1, @obj_2].have_different_values_for?(:foo)).to be_truthy
      end
    end
  end

  describe '#hash_map' do
    it 'turns tuples returned by the specified block into key-value pairs' do
      original = [[:a, :b], [:b, :c]]
      result = original.hash_map { |element| [element.first, element.last] }
      expect(result).to eq(a: :b, b: :c)
    end
  end
end
