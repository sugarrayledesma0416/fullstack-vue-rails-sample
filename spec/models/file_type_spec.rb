describe FileType do

  describe "scopes" do
    let!(:invalid_file_type) { create(:file_type) }
    let!(:allowed_file_type) { create(:allowed_file_type) }

    describe ".allowed" do
      it "returns only allowed file types" do
        results = FileType.allowed
        expect(results).to include allowed_file_type
        expect(results).not_to include invalid_file_type
      end
    end
  end

  it "returns file types ordered by extension" do
    last_file_type = create(:file_type, :extension_name => 'ghi')
    middle_file_type = create(:file_type, :extension_name => 'def')
    first_file_type = create(:file_type, :extension_name => 'abc')
    expect(FileType.all).to eq([first_file_type, middle_file_type, last_file_type])
  end

end
