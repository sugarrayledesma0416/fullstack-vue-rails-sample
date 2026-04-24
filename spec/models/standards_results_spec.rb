describe StandardsResults do
  it 'requires a cms_activity_id' do
    results = build(:standards_results, cms_activity_id: nil)
    results.save

    expect(results.errors.full_messages).to eq(['Cms activity is required'])
  end

  it 'requires a section_id' do
    results = build(:standards_results, section_id: nil)
    results.save

    expect(results.errors.full_messages).to eq(['Section is required'])
  end

  it 'requires a user_id' do
    results = build(:standards_results, user_id: nil)
    results.save

    expect(results.errors.full_messages).to eq(['User is required'])
  end

  it 'requires results_data' do
    results = build(:standards_results, results_data: nil)
    results.save

    expect(results.errors.full_messages).to eq(['Results data is required'])
  end

  describe '#create_or_update' do
    let(:user) { build_stubbed(:student) }
    let(:section) { build_stubbed(:section) }
    let(:cms_activity_id) { 12345 }
    let(:results_data) do
      {
        'db02d1dc-94e4-4cf1-81da-7871edcdf880' => {
          label: 'question_01',
          points_earned: 2,
          points_possible: 2
        },
        'bfe1f00c-b2b4-467a-bbdb-44c9f84ab0f2' => {
          label: 'question_02',
          points_earned: 0,
          points_possible: 10
        }
      }
    end

    let(:standards_results) do
      create(
        :standards_results,
        user_id: user.id,
        section_id: section.id,
        cms_activity_id: cms_activity_id,
        results_data: results_data
      )
    end

    it 'creates a new record if one does not exist' do
      expect do
        described_class.create_or_update(
          user_id: user.id,
          section_id: section.id,
          cms_activity_id: cms_activity_id,
          results_data: results_data
        )
      end.to change(described_class, :count).by(1)
    end

    it 'updates the existing record' do
      guids = standards_results.results_data.keys
      expect(standards_results.points_earned_for_guids(guids)).to eq(2)

      results_data[guids.last][:points_earned] = 9
      expect do
        described_class.create_or_update(
          user_id: user.id,
          section_id: section.id,
          cms_activity_id: cms_activity_id,
          results_data: results_data
        )
      end.not_to change(described_class, :count)
      standards_results.reload
      expect(standards_results.points_earned_for_guids(guids)).to eq(11)
    end
  end

  context 'when calculating points' do
    let(:results_data) do
      {
        'db02d1dc-94e4-4cf1-81da-7871edcdf880' => {
          label: 'question_01',
          points_earned: 2,
          points_possible: 2
        },
        'bfe1f00c-b2b4-467a-bbdb-44c9f84ab0f2' => {
          label: 'question_02',
          points_earned: 0,
          points_possible: 10
        },
        'cc63046c-26c7-40f7-9be0-b1ef46aacf23' => {
          label: 'question_03',
          points_earned: 2,
          points_possible: 2
        },
        '1f30a660-b30f-44c6-a3af-6965bde676a9' => {
          label: 'question_04',
          points_earned: 2,
          points_possible: 2
        },
        'c2d16339-b9e4-4da2-85ee-3f7c165deb78' => {
          label: 'question_05',
          points_earned: 2,
          points_possible: 2
        },
        '83bf07ae-1421-40f8-b1d0-975cec4ccdff' => {
          label: 'question_06',
          points_earned: 0,
          points_possible: 15
        },
        '6e2eb467-6864-4faf-92c0-cd3835c94acb' => {
          label: 'question_7',
          points_earned: 0,
          points_possible: 2
        },
        '1722430d-44ff-43b9-b3f7-f9ffc685fa6a' => {
          label: 'question_08',
          points_earned: 0,
          points_possible: 10
        },
        '1a747c2a-a797-435a-9cdb-f5ca5bfd3c1d' => {
          label: 'question_09',
          points_earned: 1,
          points_possible: 1
        },
        'fbb58fdd-0328-4e01-b036-8a7f0762b950' => {
          label: 'question_10',
          points_earned: 1,
          points_possible: 1
        },
        'de20bca3-1793-4359-8c5e-fed87513ba14' => {
          label: 'question_11',
          points_earned: 3,
          points_possible: 3
        }
      }
    end
    let(:standards_results) { create(:standards_results, results_data: results_data) }

    describe '#points_earned for guids' do
      it 'returns points earned for one guid' do
        guid = results_data.keys.first
        points_earned = standards_results.points_earned_for_guids(guid)

        expect(points_earned).to eq(2)
      end

      it 'returns the sum of points earned for multiple guids' do
        guids = results_data.keys.last(3)
        points_earned = standards_results.points_earned_for_guids(guids)

        expect(points_earned).to eq(5)
      end
    end

    describe '#points_possible for guids' do
      it 'returns points possible for one guid' do
        guid = results_data.keys.last
        points_possible = standards_results.points_possible_for_guids(guid)

        expect(points_possible).to eq(3)
      end

      it 'returns the sum of points possible for multiple guids' do
        guids = results_data.keys.first(3)
        points_possible = standards_results.points_possible_for_guids(guids)

        expect(points_possible).to eq(14)
      end
    end

    describe '#count_by_activity_and_section' do
      let(:activity) { create(:activity) }
      let(:section) { create(:section) }

      it 'returns the count of standards results submitted ' \
         'for an activity in a given section' do
        create(:standards_results,
               cms_activity_id: activity.cms_activity_id,
               section_id: section.id)
        expect(
          described_class.count_by_activity_and_section(activity, section)
        ).to be(1)
      end

      it 'does not count results from other activities in the same section' do
        2.times do
          create(:standards_results,
                 cms_activity_id: activity.cms_activity_id,
                 section_id: section.id)
        end

        other_activity = create(:activity)
        create(:standards_results,
               cms_activity_id: other_activity.cms_activity_id,
               section_id: section.id)

        expect(
          described_class.count_by_activity_and_section(activity, section)
        ).to be(2)
      end

      it 'does not count standards results of the same activity in a different section' do
        3.times do
          create(:standards_results,
                 cms_activity_id: activity.cms_activity_id,
                 section_id: section.id)
        end

        other_section = create(:section)
        create(:standards_results,
               cms_activity_id: activity.cms_activity_id,
               section_id: other_section.id)
        expect(
          described_class.count_by_activity_and_section(activity, section)
        ).to be(3)
      end
    end
  end
end
