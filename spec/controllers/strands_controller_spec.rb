describe StrandsController do
  describe '#index' do
    context 'with a lesson id' do
      it 'should return a list of strands' do
        lesson = build_stubbed(:lesson)
        strands = [build_stubbed(:toc_entry), build_stubbed(:toc_entry)]
        expect(Lesson).to receive(:find_by_id).with(lesson.id.to_s).and_return(lesson)
        expect(lesson).to receive(:strands).and_return(strands)
        get :index, params: { lesson_id: lesson.id }
        expect(assigns(:strands)).to eq(strands)
      end
    end

    context 'without a lesson id' do
      it 'should raise an error' do
        expect { get :index, params: { lesson_id: nil } }
          .to raise_error(ActionController::UrlGenerationError, /No route matches/)
      end
    end

    context 'with a lesson id and an override lesson id' do
      it 'should return a list of strands for the override lesson' do
        distractor_lesson = build_stubbed(:lesson)
        expected_lesson = build_stubbed(:lesson)

        distractor_strands = [build_stubbed(:toc_entry), build_stubbed(:toc_entry)]
        expected_strands = [build_stubbed(:toc_entry), build_stubbed(:toc_entry)]

        expect(Lesson).not_to receive(:find_by_id).with(distractor_lesson.id.to_s)
        expect(distractor_lesson).not_to receive(:strands)

        expect(Lesson).to receive(:find_by_id).with(expected_lesson.id.to_s).and_return(expected_lesson)
        expect(expected_lesson).to receive(:strands).and_return(expected_strands)

        get :index, params: { lesson_id: distractor_lesson.id, override_lesson_id: expected_lesson.id }

        expect(assigns(:strands)).to eq(expected_strands)
      end
    end
  end
end
