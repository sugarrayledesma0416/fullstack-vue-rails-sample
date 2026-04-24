# encoding: UTF-8

describe AssignmentBuilder, :core => true do
  describe '#activity_ids_from' do
    let(:practice_activities) do
      (0..1).map do
        create(:activity_with_assignment_group, assignment_group: 'Practice')
      end
    end

    let(:learn_activities) do
      (0..1).map do
        create(:activity_with_assignment_group, assignment_group: 'Learn')
      end
    end

    let(:assignments) do
      {
        '02/10/2014' => [
          { id: practice_activities[0].id, category: 'Practice' },
          { id: learn_activities[0].id, category: 'Learn' }
        ],
        '02/17/2014' => [
          { id: practice_activities[1].id, category: 'Practice' },
          { id: learn_activities[1].id, category: 'Learn' }
        ]
      }
    end

    it 'returns an array of activity ids' do
      expect(described_class.new.activity_ids_from(assignments)).to eq([
                                                                         practice_activities[0].id,
                                                                         learn_activities[0].id,
                                                                         practice_activities[1].id,
                                                                         learn_activities[1].id
                                                                       ])
    end
  end

  describe '#find_or_create_categories' do
    let(:course) { create(:course) }
    let(:builder) { AssignmentBuilder.new }
    let(:categories) {
      {
        'Learn' => { 'name' => 'Learn', 'weighting_percent' => 30, 'rank' => 1 },
        'Practice' => { 'name' => 'Practice', 'weighting_percent' => 30, 'rank' => 2 },
        'Interact' => { 'name' => 'Interact', 'weighting_percent' => 40, 'rank' => 3 }
      }
    }

    context 'when a category for the assignment_group exists' do
      it 'finds the existing categories' do
        learn_category = create(:category, name: 'Learn', course: course)
        practice_category = create(:category, name: 'Practice', course: course)
        interact_category = create(:category, name: 'Interact', course: course)

        expect(builder.find_or_create_categories(course, categories)).to eq({
          'learn' => learn_category,
          'practice' => practice_category,
          'interact' => interact_category
        })
      end
    end

    context 'when a category for the assignment_group does not exist' do
      it 'creates new categories' do
        result = builder.find_or_create_categories(course, categories)
        learn_category = course.categories.where(name: 'Learn').first
        practice_category = course.categories.where(name: 'Practice').first
        interact_category = course.categories.where(name: 'Interact').first

        expect(result).to eq({
          'learn' => learn_category,
          'practice' => practice_category,
          'interact' => interact_category
        })
      end
    end
  end

  describe '#build_assignments' do
    let(:practice_activities) do
      (0..3).map do
        create(:activity_with_assignment_group, assignment_group: 'Practice')
      end
    end

    let(:learn_activities) do
      (0..3).map do
        create(:activity_with_assignment_group, assignment_group: 'Learn')
      end
    end

    let(:categories) do
      {
        "learn" => create(:category, name: 'Credit'),
        "practice" => create(:category, name: 'Graded'),
        "interact" => create(:category, name: 'Quizzes'),
        "testing" => create(:category, name: 'Tests')
      }
    end

    context 'when using assignment wizard' do
      # Assignment wizard 'category' keys have learning track group values.
      # For VOL programs, the code ignores this value, instead using the activity's
      # assignment_group value to look up the matching category.
      let(:assignments) do
        {
          "02/10/2014" => [
            { id: practice_activities[0].id, category: 'Practice' },
            { id: practice_activities[1].id, category: 'Practice' },
            { id: learn_activities[0].id, category: 'Learn' },
            { id: learn_activities[1].id, category: 'Learn' }
          ],
          "02/17/2014" => [
            { id: practice_activities[2].id, category: 'Practice' },
            { id: practice_activities[3].id, category: 'Practice' },
            { id: learn_activities[2].id, category: 'Learn' },
            { id: learn_activities[3].id, category: 'Learn' }
          ]
        }
      end

      it 'returns a hash of due dates mapped to assignment attributes' do
        expect(described_class.new.build_assignments(categories, assignments))
          .to eq(
            [
              {
                activity_id: practice_activities[0].id,
                category: categories['practice'],
                rank: 1,
                due_date: '02/10/2014',
                individually_assignable: false,
                is_igc: false
              },
              {
                activity_id: practice_activities[1].id,
                category: categories['practice'],
                rank: 2,
                due_date: '02/10/2014',
                individually_assignable: false,
                is_igc: false
              },
              {
                activity_id: learn_activities[0].id,
                category: categories['learn'],
                rank: 3,
                due_date: '02/10/2014',
                individually_assignable: false,
                is_igc: false
              },
              {
                activity_id: learn_activities[1].id,
                category: categories['learn'],
                rank: 4,
                due_date: '02/10/2014',
                individually_assignable: false,
                is_igc: false
              },
              {
                activity_id: practice_activities[2].id,
                category: categories['practice'],
                rank: 1,
                due_date: '02/17/2014',
                individually_assignable: false,
                is_igc: false
              },
              {
                activity_id: practice_activities[3].id,
                category: categories['practice'],
                rank: 2,
                due_date: '02/17/2014',
                individually_assignable: false,
                is_igc: false
              },
              {
                activity_id: learn_activities[2].id,
                category: categories['learn'],
                rank: 3,
                due_date: '02/17/2014',
                individually_assignable: false,
                is_igc: false
              },
              {
                activity_id: learn_activities[3].id,
                category: categories['learn'],
                rank: 4,
                due_date: '02/17/2014',
                individually_assignable: false,
                is_igc: false
              }
            ]
          )
      end

      it 'raises an exception if a category is not found in the category mapping' do
        learn_activities.last.update(assignment_group: nil)
        assignments['02/17/2014'].last[:category] = 'Category Woo'

        expect { described_class.new.build_assignments(categories, assignments) }
          .to raise_error(RuntimeError, 'Category Category Woo not found in category mapping.')
      end

      it 'gracefully handles nil assignment arrays' do
        assignments = { '02/25/2014' => nil }
        expect(described_class.new.build_assignments(categories, assignments)).to eq([])
      end

      it 'gracefully handles empty assignment arrays' do
        assignments = { '02/25/2014' => [] }
        expect(described_class.new.build_assignments(categories, assignments)).to eq([])
      end

      context 'when an assignment has an activity with an assignment group '\
              'that matches a gradebook category name on the course' do
        let(:assignment_with_category_foo) do
          {
            '02/10/2014' => [
              { id: practice_activities[0].id, category: 'foo' }
            ]
          }
        end

        let(:categories) do
          {
            'foo' => create(:category, name: 'foo'),
            'practice' => create(:category, name: 'practice')
          }
        end

        it 'creates an assignment with the category that matches the original assignment' do
          expect(
            described_class.new.build_assignments(categories, assignment_with_category_foo)
          ).to eq(
            [
              {
                activity_id: practice_activities[0].id,
                category: categories['foo'],
                rank: 1,
                due_date: '02/10/2014',
                individually_assignable: false,
                is_igc: false
              }
            ]
          )
        end
      end
    end

    context 'when using express course' do
      let(:express_categories) do
        {
          'credit' => create(:category, name: 'Credit'),
          'graded' => create(:category, name: 'Graded'),
          'quizzes' => create(:category, name: 'Quizzes'),
          'tests' => create(:category, name: 'Tests')
        }
      end

      # express course 'category' keys have category name values
      let(:express_assignments) do
        {
          '02/10/2014' => [
            { id: practice_activities[0].id, category: 'Credit' },
            { id: practice_activities[1].id, category: 'Graded' },
            { id: learn_activities[0].id, category: 'Quizzes' },
            { id: learn_activities[1].id, category: 'Tests' }
          ],
          '02/17/2014' => [
            { id: practice_activities[2].id, category: 'Credit' },
            { id: practice_activities[3].id, category: 'Graded' },
            { id: learn_activities[2].id, category: 'Quizzes' },
            { id: learn_activities[3].id, category: 'Tests' }
          ]
        }
      end

      it 'returns a hash of due dates mapped to assignment attributes' do
        expect(described_class.new.build_assignments(
                 express_categories, express_assignments
               )).to eq(
                 [
                   {
                     activity_id: practice_activities[0].id,
                     category: express_categories['credit'],
                     rank: 1,
                     due_date: '02/10/2014',
                     individually_assignable: false,
                     is_igc: false,
                   },
                   {
                     activity_id: practice_activities[1].id,
                     category: express_categories['graded'],
                     rank: 2,
                     due_date: '02/10/2014',
                     individually_assignable: false,
                     is_igc: false
                   },
                   {
                     activity_id: learn_activities[0].id,
                     category: express_categories['quizzes'],
                     rank: 3,
                     due_date: '02/10/2014',
                     individually_assignable: false,
                     is_igc: false
                   },
                   {
                     activity_id: learn_activities[1].id,
                     category: express_categories['tests'],
                     rank: 4,
                     due_date: '02/10/2014',
                     individually_assignable: false,
                     is_igc: false
                   },
                   {
                     activity_id: practice_activities[2].id,
                     category: express_categories['credit'],
                     rank: 1,
                     due_date: '02/17/2014',
                     individually_assignable: false,
                     is_igc: false
                   },
                   {
                     activity_id: practice_activities[3].id,
                     category: express_categories['graded'],
                     rank: 2,
                     due_date: '02/17/2014',
                     individually_assignable: false,
                     is_igc: false
                   },
                   {
                     activity_id: learn_activities[2].id,
                     category: express_categories['quizzes'],
                     rank: 3,
                     due_date: '02/17/2014',
                     individually_assignable: false,
                     is_igc: false
                   },
                   {
                     activity_id: learn_activities[3].id,
                     category: express_categories['tests'],
                     rank: 4,
                     due_date: '02/17/2014',
                     individually_assignable: false,
                     is_igc: false
                   }
                 ]
               )
      end
    end

    context 'when assignments include IGC activities' do
      let(:instructor) { create(:user) }
      let(:igc_activity) { create(:activity, instructor_id: instructor.id) }
      let(:regular_activity) { create(:activity, instructor_id: nil) }

      let(:mixed_assignments) do
        {
          '02/10/2014' => [
            { id: igc_activity.id, category: 'Practice' },
            { id: regular_activity.id, category: 'Learn' }
          ]
        }
      end

      it 'identifies IGC activities with instructor_id present as IGC' do
        result = described_class.new.build_assignments(categories, mixed_assignments)

        igc_assignment = result.find { |a| a[:activity_id] == igc_activity.id }

        expect(igc_assignment[:is_igc]).to be true
      end

      it 'identifies regular activities without instructor_id as non-IGC' do
        result = described_class.new.build_assignments(categories, mixed_assignments)

        regular_assignment = result.find { |a| a[:activity_id] == regular_activity.id }

        expect(regular_assignment[:is_igc]).to be false
      end

      it 'handles activities with instructor_id = nil as non-IGC' do
        nil_instructor_activity = create(:activity, instructor_id: nil)
        assignments_with_nil = {
          '02/10/2014' => [
            { id: nil_instructor_activity.id, category: 'Practice' }
          ]
        }

        result = described_class.new.build_assignments(categories, assignments_with_nil)

        expect(result.first[:is_igc]).to be false
      end
    end
  end
end
