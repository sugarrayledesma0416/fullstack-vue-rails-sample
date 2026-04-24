describe LessonSelectorHelper do
  include LessonSelectorHelper

  describe 'format_lesson_name_for_screenreader' do
    context 'when lang attribute is not defined' do
      it 'formats the content as two divs with default lang attribute' do
        result = format_lesson_name_for_screenreader('Unit 1 | Star trek: <span lang="">Viaje a las estrellas</span>', 'en')
        expect(result).to eq(
          "<div class='u-dis-inline' lang='en'>Unit 1 | Star trek: </div>"\
          "<div class='u-dis-inline' lang='en'>Viaje a las estrellas</div>"
        )
      end
    end

    context 'when the lesson name has no span tags' do
      it 'returns the lesson name with no changes' do
        result = format_lesson_name_for_screenreader('Unit 1 | Star trek beyond the galaxy', 'en')
        expect(result).to eq('Unit 1 | Star trek beyond the galaxy')
      end
    end

    context 'when the entire lesson name is inside of a span with a lang attribute' do
      it 'formats the content as one div with the expected lang attribute' do
        result = format_lesson_name_for_screenreader('<span lang="en">Unit 2 | Star trek</span>', 'es')
        expect(result).to eq("<div class='u-dis-inline' lang='en'>Unit 2 | Star trek</div>")
      end
    end

    context 'when the lesson name has content outside a span and has a span with a lang attribute' do
      context 'when the span is at one end of the lesson name' do
        it 'formats the content as two divs with the expected lang attributes' do
          result = format_lesson_name_for_screenreader('Unit 1 | Star trek: <span lang="es">Viaje a las estrellas</span>', 'en')
          expect(result).to eq(
            "<div class='u-dis-inline' lang='en'>Unit 1 | Star trek: </div>"\
            "<div class='u-dis-inline' lang='es'>Viaje a las estrellas</div>"
          )
        end
      end

      context 'when the span is in the middle of the lesson name' do
        it 'formats the content as three divs with the expected lang attributes' do
          result = format_lesson_name_for_screenreader('Unit 1 | Star trek: <span lang="es">Viaje a las estrellas</span> beyond the galaxy', 'en')
          expect(result).to eq(
            "<div class='u-dis-inline' lang='en'>Unit 1 | Star trek: </div>"\
            "<div class='u-dis-inline' lang='es'>Viaje a las estrellas</div>"\
            "<div class='u-dis-inline' lang='en'> beyond the galaxy</div>"
          )
        end
      end
    end

    context 'when the lesson name has content outside a span and has span with other attribute other than lang' do
      it 'formats the content as two divs with the default lang attribute' do
        result = format_lesson_name_for_screenreader('Unit 1 | Star trek: <span class="u-dis-inline">Viaje a las estrellas</span>', 'en')
        expect(result).to eq(
          "<div class='u-dis-inline' lang='en'>Unit 1 | Star trek: </div>"\
          "<div class='u-dis-inline' lang='en'>Viaje a las estrellas</div>"
        )
      end
    end

    context 'when the lesson name contains another combination of tags including the span tag' do
      context 'when bold tag is at one start of the lesson name' do
        it 'formats the content as two divs, the first one contains the bold tag' do
          result = format_lesson_name_for_screenreader('<b>Unit 1 | Star trek:</b><span lang="es">Viaje a las estrellas</span>', 'en')
          expect(result).to eq(
            "<div class='u-dis-inline' lang='en'><b>Unit 1 | Star trek:</b></div>"\
            "<div class='u-dis-inline' lang='es'>Viaje a las estrellas</div>"
          )
        end
      end

      context 'when bold tag is at the second span tag' do
        it 'formats the content as two divs, the second one contains the bold tag' do
          result = format_lesson_name_for_screenreader('Unit 1 | Star trek: <span lang="es"><b>Viaje a las estrellas</b></span>', 'en')
          expect(result).to eq(
            "<div class='u-dis-inline' lang='en'>Unit 1 | Star trek: </div>"\
            "<div class='u-dis-inline' lang='es'><b>Viaje a las estrellas</b></div>"
          )
        end
      end

      # edge case, out of scope, workaround available
      context 'when bold tag is around the span tag' do
        xit 'formats the content as two divs, withouth the bold tags' do
          result = format_lesson_name_for_screenreader('Unit 1 | Star trek: <b><span lang="es">Viaje a las estrellas</span></b>', 'en')
          expect(result).to eq(
            "<div class='u-dis-inline' lang='en'>Unit 1 | Star trek: </div>"\
            "<div class='u-dis-inline' lang='es'>Viaje a las estrellas</div>"
          )
        end
      end

      # edge case, out of scope, workaround available
      context 'when bold tag is mislocated along with the span tag' do
        xit 'formats the content as two divs, withouth the bold tags' do
          result = format_lesson_name_for_screenreader('Unit 1 | Star trek: <span lang="es"><b>Viaje a las estrellas</span></b>', 'en')
          expect(result).to eq(
            "<div class='u-dis-inline' lang='en'>Unit 1 | Star trek: </div>"\
            "<div class='u-dis-inline' lang='es'>Viaje a las estrellas</div>"
          )
        end
      end

      context 'when em tag is at one start of the lesson name' do
        it 'formats the content as two divs, the first one contains the em tag' do
          result = format_lesson_name_for_screenreader('<em>Unit 1 | Star trek:</em><span lang="es">Viaje a las estrellas</span>', 'en')
          expect(result).to eq(
            "<div class='u-dis-inline' lang='en'><em>Unit 1 | Star trek:</em></div>"\
            "<div class='u-dis-inline' lang='es'>Viaje a las estrellas</div>"
          )
        end
      end
    end
  end
end
