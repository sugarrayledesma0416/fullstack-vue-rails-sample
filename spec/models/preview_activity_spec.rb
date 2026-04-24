describe PreviewActivity do
  let(:xml_content) do
    <<~CONTENT
    <?xml version="1.0" encoding="UTF-8"?>
    <activity activity_type="multiple_choice" title="A  primera  vista" language="es">
      <dl>Choose the correct answers to the questions about the lesson opener photo.</dl>
      <items>
        <item>
          <prompt>¿Cuántos chicos hay en la foto?</prompt>
          <choices>
            <distractor>cuatro</distractor>
            <answer>dos</answer>
          </choices>
        </item>
      </items>
    </activity>
    CONTENT
  end
  let(:concept) { create(:concept) }
  let(:lesson) { create(:lesson) }

  it 'requires certain params' do
    expect { described_class.new }
      .to raise_error(
            ArgumentError, 
            'activity_type, cms_revision_id, concept_id, content, '\
            'lesson_id, toc_location required!'
          )
  end

  context 'with valid params' do
    let(:activity_params) do
      {
        activity_type: 'multiple_choice',
        cms_revision_id: 123,
        concept_id: concept.id,
        content: xml_content,
        lesson_id: lesson.id,
        toc_location: concept.id
      }
    end
    let(:activity) { described_class.new(activity_params) }

    it 'creates a valid activity' do
      expect(activity).to be_valid
      expect(activity.content_object).to_not be_nil
    end

    it 'does not write content to the disk' do
      expect(File.exist?(activity.content_filepath)).to be false 
    end

    it 'cannot be saved' do
      expect { activity.save }.to raise_error ActiveRecord::ReadOnlyRecord
    end

    it 'sets the activity_type' do
      expect(activity.activity_type).to eq activity_params[:activity_type]
    end

    it 'sets the program' do
      expect(activity.program).to eq(lesson.program)
    end
  end
end
