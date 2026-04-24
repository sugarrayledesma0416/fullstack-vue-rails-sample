describe Smartbook::MatchingResponseParser do
  let(:smartbook_data) { SmartbookTest::SmartbookData.new }
  let(:response_1_incorrect_1_missing) do
    smartbook_data.question_6_response_1_incorrect_1_missing
  end
  let(:response_all_correct) do
    smartbook_data.question_6_response_correct
  end
  let(:student_response) { response_1_incorrect_1_missing }
  let(:submission_data) do
    smartbook_data.question_6_matching.answered_submission_data(
      response: student_response
    )
  end
  let(:response) do
    described_class.new(Xapi::Statement.new(submission_data))
  end

  describe '#formatted_correct_response' do
    it 'returns an empty string' do
      expect(response.formatted_correct_response).to eq('')
    end
  end

  describe '#formatted_student_response' do
    it 'returns an empty string' do
      expect(response.formatted_student_response).to eq('')
    end
  end

  describe '#all_correct?' do
    context 'when the student answered all questions correctly,' do
      let(:student_response) { response_all_correct }

      it 'returns true' do
        expect(response).to be_all_correct
      end
    end

    context 'when the student did not answer all questions correctly,' do
      it 'returns false' do
        expect(response).not_to be_all_correct
      end
    end
  end

  describe '#incorrect_response_count' do
    context 'when the student answered all questions correctly,' do
      let(:student_response) { response_all_correct }

      it 'returns zero' do
        expect(response.incorrect_response_count).to eq(0)
      end
    end

    context 'when the student did not answer all questions correctly,' do
      it 'returns the number of incorrect responses' do
        expect(response.incorrect_response_count).to eq(2)
      end
    end
  end

  describe '#entries' do
    let(:submission_data) do
      question.answered_submission_data(response: student_response)
    end

    context 'when the matching subactivity is a matching question' do
      let(:question) { smartbook_data.question_6_matching }
      let(:student_response) { response_1_incorrect_1_missing }

      it 'returns an array of hashes containg the prompt, the correct response ' \
        'and the student response for each question' do
        expect(response.entries).to eq(
          [
            {
              prompt: 'Who welcomes the pairs?.',
              response: 'La familia Pérez.',
              student_response: 'La familia Pérez.'
            },
            {
              prompt: 'Who is Marisa?.',
              response: 'La hija de Carmen y Luis.',
              student_response: 'La hija de Carmen y Luis.'
            },
            {
              prompt: 'How do the characters feel?.',
              response: 'Contentos.',
              student_response: 'Muy gracioso.'
            },
            {
              prompt: 'How many siblings does Marisa have?.',
              response: 'Dos.',
              student_response: 'Dos.'
            },
            {
              prompt: 'What is Mack like?.',
              response: 'Muy gracioso.',
              student_response: nil
            }
          ]
        )
      end
    end

    context 'when the matching subactivity is dropdown choice' do
      let(:question) { smartbook_data.question_7_dropdown_choice }
      let(:student_response) { smartbook_data.question_7_response_incorrect }

      it 'returns an array of hashes containg the prompt, the correct response ' \
        'and the student response for each question' do
        expect(response.entries).to eq(
          [
            {
              prompt: '1. México tiene    ciento    siento    veinte millones de habitantes.',
              response: 'ciento',
              student_response: 'siento'
            },
            {
              prompt: '2. En Washington, D.C. hay edificios muy    vellos    bellos    .',
              response: 'bellos',
              student_response: 'bellos'
            },
            {
              prompt: '3. En las zonas desérticas la temperatura puede subir a más de    sien    cien    grados.',
              response: 'cien',
              student_response: 'cien'
            },
            {
              prompt: '4. En México hay varias    sierras    cierras    que atraviesan el país de norte a sur.',
              response: 'sierras',
              student_response: 'cierras'
            }
          ]
        )
      end
    end

    context 'when the matching subactivity is binary choice' do
      let(:question) { smartbook_data.question_8_binary_choice }
      let(:student_response) { smartbook_data.question_8_response_incorrect }

      it 'returns an array of hashes containg the prompt, the correct response ' \
        'and the student response for each question' do
        expect(response.entries).to eq(
          [
            {
              prompt: '1. Los pinos son comunes en las praderas.',
              response: 'false',
              student_response: 'true'
            },
            {
              prompt: '2. Los montes y las llanuras forman parte de la geografía de un país.',
              response: 'true',
              student_response: 'true'
            },
            {
              prompt: '3. La zona metropolitana no es un área muy poblada.',
              response: 'false',
              student_response: 'false'
            },
            {
              prompt: '4. En las regiones semiáridas no hay mucho pasto.',
              response: 'true',
              student_response: 'false'
            },
            {
              prompt: '5. Un subcontinente es mayor que un continente.',
              response: 'false',
              student_response: 'true'
            }
          ]
        )
      end
    end

    context 'when the matching subactivity is a drag and drop' do
      let(:question) { smartbook_data.question_9_drag_drop }
      let(:student_response) { smartbook_data.question_9_response_incorrect }

      it 'returns an array of hashes containg the prompt, the correct response ' \
        'and the student response for each question' do
        expect(response.entries).to eq(
          [
            {
              prompt: 'a. Tiene lugar la Revolución Mexicana.',
              response: 'Respuesta      4                Respuesta incorrecta      e. El cura Hidalgo convoca al pueblo con “El grito de Dolores',
              student_response: 'Respuesta      2                Respuesta incorrecta      a. Tiene lugar la Revolución Mexicana.',
            },
            {
              prompt: 'b. Hernán Cortés y los españoles toman Tenochtitlán.',
              response: 'Respuesta      1                Respuesta correcta      b. Hernán Cortés y los españoles toman Tenochtitlán.',
              student_response: 'Respuesta      1                Respuesta correcta      b. Hernán Cortés y los españoles toman Tenochtitlán.',
            },
            {
              prompt: 'c. México se independiza de España.',
              response: 'Respuesta      3                Respuesta correcta      c. México se independiza de España.',
              student_response: 'Respuesta      3                Respuesta correcta      c. México se independiza de España.',
            },
            {
              prompt: 'd. Llegaron trabajadores migratorios mexicanos a Estados Unidos.',
              response: 'Respuesta      1                Respuesta correcta      b. Hernán Cortés y los españoles toman Tenochtitlán.',
              student_response: 'Respuesta      5                Respuesta incorrecta      d. Llegaron trabajadores migratorios mexicanos a Estados Unidos.',
            },
            {
              prompt: 'e. El cura Hidalgo convoca al pueblo con “El grito de Dolores”.',
              response: 'Respuesta      2                Respuesta incorrecta      a. Tiene lugar la Revolución Mexicana.',
              student_response: 'Respuesta      4                Respuesta incorrecta      e. El cura Hidalgo convoca al pueblo con “El grito de Dolores'
            }
          ]
        )
      end
    end

    context 'when the matching subactivity is a word search' do
      let(:question) { smartbook_data.question_11_word_search }
      let(:student_response) { smartbook_data.question_11_response_incorrect }

      it 'returns an array of hashes containg the prompt, the correct response ' \
        'and the student response for each question' do
        expect(response.entries).to eq(
          [
            {
              prompt: '',
              response: 'GRACIAS',
              student_response: 'GRACIAS'
            },
            {
              prompt: '',
              response: 'SEÑORA',
              student_response: ''
            },
            {
              prompt: '',
              response: 'HASTAPRONTO',
              student_response: 'HASTAPRONTO'
            },
            {
              prompt: '',
              response: 'MERCADO',
              student_response: 'MERCADO'
            },
            {
              prompt: '',
              response: 'TEPRESENTO',
              student_response: ''
            },
            {
              prompt: '',
              response: 'MUCHOGUSTO',
              student_response: ''
            },
            {
              prompt: '',
              response: 'BUENOSDÍAS',
              student_response: ''
            },
            {
              prompt: '',
              response: 'ADIÓS',
              student_response: ''
            }
          ]
        )
      end
    end
  end
end
