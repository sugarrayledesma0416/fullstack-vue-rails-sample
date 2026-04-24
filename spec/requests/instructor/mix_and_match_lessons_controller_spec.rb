describe Instructor::MixAndMatchLessonsController do
  describe 'GET #index' do
    let(:program) { create(:program) }
    let(:unit_1) { create(:unit, program: program, rank: 1) }
    let(:unit_2) { create(:unit, program: program, rank: 2) }

    context 'with a single-tier program' do
      it 'returns a json array of units with only one array of lessons ids and names, sorted by unit rank' do
        # create in reverse order to verify sorting
        lesson_2 = create(:lesson, name: 'Lesson 2', unit: unit_2)
        lesson_1 = create(:lesson, name: 'Lesson 1', unit: unit_1)

        get instructor_mix_and_match_lessons_path(program_id: program.id)

        expect(JSON.parse(response.body)).to eq(
          [
            {
              "id" => unit_1.id,
              "is_multi_lesson" => false,
              "lessons" => [
                {
                  'displayName' => lesson_1.display_name,
                  'id' => lesson_1.id,
                  'name' => lesson_1.name
                }
              ],
              "name"=> unit_1.name
            },
            {
              "id" => unit_2.id,
              "is_multi_lesson" => false,
              "lessons" => [
                {
                  'displayName' => lesson_2.display_name,
                  'id' => lesson_2.id,
                  'name' => lesson_2.name
                }
              ],
              "name" => unit_2.name
            }
          ]
        )
      end
    end

    context 'with a multi-tier program' do
      it 'returns a json array of units within an array of lesson ids and names, sorted by unit rank' do
        # create in reverse order to verify sorting
        lesson_3 = create(:lesson, name: 'Lesson 3', unit: unit_2)
        lesson_4 = create(:lesson, name: 'Lesson 4', unit: unit_2)
        lesson_1 = create(:lesson, name: 'Lesson 1', unit: unit_1)
        lesson_2 = create(:lesson, name: 'Lesson 2', unit: unit_1)

        get instructor_mix_and_match_lessons_path(program_id: program.id)

        expect(JSON.parse(response.body)).to eq(
          [
            {
              "id" => unit_1.id,
              "is_multi_lesson" => true,
              "lessons" => [
                {
                  'displayName' => lesson_1.display_name,
                  'id' => lesson_1.id,
                  'name' => lesson_1.name
                },
                {
                  'displayName' => lesson_2.display_name,
                  'id' => lesson_2.id,
                  'name' => lesson_2.name
                }
              ],
              "name"=> unit_1.name
            },
            {
              "id" => unit_2.id,
              "is_multi_lesson" => true,
              "lessons" => [
                {
                  'displayName' => lesson_3.display_name,
                  'id' => lesson_3.id,
                  'name' => lesson_3.name
                },
                {
                  'displayName' => lesson_4.display_name,
                  'id' => lesson_4.id,
                  'name' => lesson_4.name
                }
              ],
              "name" => unit_2.name
            }
          ]
        )
      end
    end
  end
end
