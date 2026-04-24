describe TreeNode do
  describe '#children' do
    let(:node) { described_class.new('parent') }

    it 'returns an empty array if no children have been assigned' do
      expect(node.children).to eq([])
    end

    it 'returns an array of children that have been assigned' do
      child_objects = ['child 1', 'child 2']
      node.children = child_objects
      expect(node.children).to eq(child_objects)
    end
  end
end
