describe Course, core: true do
  let(:school) { create(:school) }
  let(:program) { create(:program, unit_label: 'unit') }
  let(:unit_1) { create(:unit, program: program, rank: 1) }
  let(:unit_2) { create(:unit, program: program, rank: 2) }
  let(:owner) { create(:instructor) }

  let(:params) do
    {
      end_date: 10.days.from_now,
      first_unit: unit_1,
      last_unit: unit_2,
      name: 'valid_name',
      owner: owner,
      program: program,
      school: school,
      start_date: 10.days.ago
    }
  end

  describe 'callbacks' do
    describe 'validate_dependents' do
      let(:cat_1) { { name: 'Cat 1', weighting_percent: 20.0 } }
      let(:cat_2) { { name: 'Cat 2', weighting_percent: 20.0 } }

      context 'when category weights add up to 100,' do
        let(:course) do
          create(
            :course,
            categories_attributes: [name: 'Cat 0', weighting_percent: 100.0]
          )
        end
        let(:category_0) { course.categories.reload.first }
        let(:cat_0_destroy_attrs) do
          {
            _destroy: true,
            id: category_0.id,
            name: category_0.name,
            weighting_percent: 100.0
          }
        end

        it 'does not allow destroying an existing category with assignments' do
          section = create(:section, course: course)
          create(:assignment, category_id: category_0.id, section: section)

          new_category_attrs = { name: 'Cat 1', weighting_percent: 100.0 }

          course.update(
            categories_attributes: [cat_0_destroy_attrs, new_category_attrs]
          )
          expect(course.all_error_messages).to eq(
            ['Category with assignments cannot be deleted.']
          )
        end

        it 'does not allow creating two categories with the same name' do
          cat_2_dupe = { name: 'Cat 2', weighting_percent: 60.0 }
          category_attrs = { categories_attributes: [cat_1, cat_2, cat_2_dupe] }

          course = build(:course, params.merge(category_attrs))
          course.save

          expect(course.errors.full_messages).to eq(
            [
              "Categories name cannot be 'Cat 2' because this course already " \
              'has a category with that name. Please choose a different name.'
            ]
          )
        end

        it 'allows destroying an existing category without assignments' do
          cat_3 = { name: 'Cat 3', weighting_percent: 60.0 }
          course.update(
            categories_attributes: [cat_1, cat_2, cat_3, cat_0_destroy_attrs]
          )
          expect(course.all_error_messages).to eql([])
        end
      end

      context 'when category weights do not add up to 100%,' do
        it 'adds an error to course' do
          category_attrs = { categories_attributes: [cat_1, cat_2] }
          course = build(:course, params.merge(category_attrs))
          course.save
          expect(course.errors.full_messages).to eq(
            ['Category weights must add up to 100%, currently 40%']
          )
        end

        context 'when one of the category is marked for destruction,' do
          it 'still adds an error to course' do
            cat_3 = { name: 'Cat 3', weighting_percent: 60.0, _destroy: true }
            category_attrs = { categories_attributes: [cat_1, cat_2, cat_3] }

            course = build(:course, params.merge(category_attrs))
            course.save

            expect(course.errors.full_messages).to eq(
              ['Category weights must add up to 100%, currently 40%']
            )
          end
        end
      end
    end

    context 'update_gradebook' do
      context 'after commit' do
        let(:course) { create(:course) }

        it 'triggers update_gradebook in after_commit' do
          course.name = 'New Name'
          expect(course).to receive(:update_gradebook)
          course.save
        end

        it 'triggers notify_update when course is created' do
          acourse = described_class.new
          acourse.name = 'Course 1'
          acourse.program = create(:program)
          acourse.owner = create(:instructor)
          acourse.start_date = DateTime.now
          acourse.end_date = DateTime.now + 3.month
          acourse.first_unit = create(:unit)
          acourse.last_unit = acourse.first_unit
          acourse.school = create(:school)
          expect(acourse).to receive(:notify_update)
          acourse.save
        end

        it 'triggers notify_deletion for an archived course' do
          acourse = described_class.new
          acourse.name = 'Course 1'
          acourse.program = create(:program)
          acourse.owner = create(:instructor)
          acourse.start_date = DateTime.now
          acourse.end_date = DateTime.now + 3.month
          acourse.first_unit = create(:unit)
          acourse.last_unit = acourse.first_unit
          acourse.school = create(:school)
          acourse.is_archived = true
          expect(acourse).to receive(:notify_deletion)
          acourse.save
        end

        it 'triggers notify_deletion for a destroyed course' do
          acourse = described_class.new
          acourse.name = 'Course 1'
          acourse.program = create(:program)
          acourse.owner = create(:instructor)
          acourse.start_date = DateTime.now
          acourse.end_date = DateTime.now + 3.month
          acourse.first_unit = create(:unit)
          acourse.last_unit = acourse.first_unit
          acourse.school = create(:school)
          acourse.save
          expect(acourse).to receive(:notify_deletion)
          acourse.destroy
        end
      end
    end
  end

  context 'validate assign_rostering_attrs' do
    around do |example|
      Dangerfield::Gatekeeper.instance.disabled = false
      example.run
      Dangerfield::Gatekeeper.instance.disabled = true
    end

    it 'sets guid, request_id' do
      course_with_owner = create(:course,:owner => owner)
      expect(course_with_owner.guid).not_to be_nil
      expect(course_with_owner.request_id).not_to be_nil
    end
  end

  describe 'scopes' do
    describe '.open' do
      it 'returns only courses with end dates that are today or later' do
        ends_today = create(:course, end_date: Date.today)
        ends_tomorrow = create(:course, end_date: Date.tomorrow)
        ended_yesterday = create(:course, end_date: Date.yesterday, allow_past_end_date: true)
        expect(Course.open).to match_array([ends_today, ends_tomorrow])
      end
    end

    describe '.closed' do
      it 'returns only courses with end dates that are earlier than today' do
        ends_today = create(:course, end_date: Date.today)
        ends_tomorrow = create(:course, end_date: Date.tomorrow)
        ended_yesterday = create(:course, end_date: Date.yesterday, allow_past_end_date: true)
        expect(Course.closed).to eq([ended_yesterday])
      end
    end

    describe '.editable' do
      it 'returns only courses that ended less than 1 month ago' do
        one_month_ago = (Time.zone.now.to_date - 1.month)
        ended_31_days_ago = create(
          :course,
          end_date: (one_month_ago - 1.day),
          allow_past_end_date: true,
          start_date: 1.year.ago.to_date
        )
        ended_30_days_ago = create(
          :course,
          end_date: one_month_ago,
          allow_past_end_date: true,
          start_date: 1.year.ago.to_date
        )
        ended_29_days_ago = create(
          :course,
          end_date: (one_month_ago + 1.day),
          allow_past_end_date: true,
          start_date: 1.year.ago.to_date
        )
        expect(Course.editable).to match_array([ended_29_days_ago, ended_30_days_ago])
      end
    end

    describe '.by_program' do
      it 'returns all courses by program' do
        program = build_stubbed(:program)
        this_program_course = create(:course, :program => program)
        other_program_course = create(:course, :program => build_stubbed(:program))
        expect(Course.by_program(program)).to eq([this_program_course])
      end
    end

    describe '.by_school' do
      it 'returns all courses by school' do
        school = build_stubbed(:school)
        this_school_course = create(:course, :school => school)
        other_school_course = create(:course, :school => build_stubbed(:school))
        expect(Course.by_school(school)).to eq([this_school_course])
      end
    end

    describe '.by_year' do
      it 'returns only courses beginning in the specified year' do
        course_starting_in_2009 = create(:closed_course, :start_date => Date.parse('2009-01-01'), :end_date => Date.parse('2011-01-01'))
        course_starting_in_2010 = create(:closed_course, :start_date => Date.parse('2010-01-01'), :end_date => Date.parse('2011-01-01'))
        course_ending_in_2009 = create(:closed_course, :start_date => Date.parse('2008-01-01'), :end_date => Date.parse('2009-01-01'))

        expect(Course.by_year(2009)).to eq([course_starting_in_2009])
      end
    end

    describe ".drafts_by_owner" do
      it "returns draft courses for the given user" do
        expected_owner = create(:instructor)
        another_user = create(:instructor)
        expected_draft_1 = create(:draft_course, :owner => expected_owner)
        expected_draft_2 = create(:draft_course, :owner => expected_owner)
        create(:draft_course, :owner => another_user)
        create(:course)
        expect(Course.drafts_by_owner(expected_owner)).to match_array([expected_draft_1, expected_draft_2])
      end
    end

    describe '.open_by_program' do
      it 'returns only courses with end dates that are today or later for the specified program' do
        program = build_stubbed(:program)
        ends_today = create(:course, end_date: Date.today, program:)
        ends_tomorrow = create(:course, end_date: Date.tomorrow, program:)
        ended_yesterday = create(
          :course,
          end_date: Date.yesterday,
          allow_past_end_date: true,
          program:
        )
        other_program_course = create(
          :course,
          end_date: Date.tomorrow,
          program: build_stubbed(:program)
        )
        expect(Course.open_by_program(program)).to match_array([ends_today, ends_tomorrow])
      end
    end

    describe '.closed_by_program' do
      it 'returns only courses with end dates before today for the specified program' do
        program = build_stubbed(:program)
        ends_today = create(:course, end_date: Date.today, program:)
        ends_tomorrow = create(:course, end_date: Date.tomorrow, program:)
        ended_yesterday = create(
          :course,
          end_date: Date.yesterday,
          allow_past_end_date: true,
          program:
        )
        other_program_course = create(
          :course,
          end_date: Date.yesterday,
          allow_past_end_date: true,
          program: build_stubbed(:program)
        )
        expect(Course.closed_by_program(program)).to eq([ended_yesterday])
      end
    end

    describe '.editable_by_program' do
      it 'returns only courses that ended less than 30 days from today for the specified program' do
        program = build_stubbed(:program)
        one_month_ago = (Time.zone.now.to_date - 1.month)
        ended_31_days_ago = create(
          :course,
          end_date: (one_month_ago - 1.day),
          allow_past_end_date: true,
          start_date: 1.year.ago.to_date,
          program:
        )
        ended_30_days_ago = create(
          :course,
          end_date: one_month_ago,
          allow_past_end_date: true,
          start_date: 1.year.ago.to_date,
          program:
        )
        ended_29_days_ago = create(
          :course,
          end_date: (one_month_ago + 1.day),
          allow_past_end_date: true,
          start_date: 1.year.ago.to_date,
          program:
        )
        other_program_course = create(
          :course,
          end_date: (one_month_ago + 1.day),
          allow_past_end_date: true,
          start_date: 1.year.ago.to_date,
          program: build_stubbed(:program)
        )
        expect(Course.editable_by_program(program)).to match_array([ended_29_days_ago, ended_30_days_ago])
      end
    end

    describe 'enterprise scopes' do
      let!(:enterprise_course) { create(:enterprise_course) }
      let!(:non_enterprise_course) { create(:course) }

      describe '.non_enterprise' do
        it 'returns only non enterprise courses' do
          result_set = described_class.non_enterprise

          expect(result_set).to include(non_enterprise_course)
          expect(result_set).not_to include(enterprise_course)
        end
      end

      describe '.enterprise' do
        it 'returns only enterprise courses' do
          result_set = described_class.enterprise

          expect(result_set).to include(enterprise_course)
          expect(result_set).not_to include(non_enterprise_course)
        end
      end
    end
  end

  describe 'enterprise relationships' do
    subject(:course) { create(:enterprise_course) }

    let!(:enterprise_section) { create(:enterprise_section, course:) }
    let!(:non_enterprise_section) { create(:section, course:) }

    before { course.reload }

    describe 'sections' do
      it { expect(course.sections).to include(non_enterprise_section) }
      it { expect(course.sections).not_to include(enterprise_section) }
    end

    describe 'enterprise_section' do
      it { expect(course.enterprise_section).to eq(enterprise_section) }
      it { expect(course.enterprise_section).not_to eq(non_enterprise_section) }
    end
  end

  describe '#<=>' do
    it 'sorts by created_at' do
      earlier = create(:course, name: 'earlier', created_at: '2010-01-01')
      recent = create(:course, name: 'recent', created_at: '2011-01-01')
      expect([earlier, recent].sort).to eq([recent, earlier])
      expect([recent, earlier].sort).to eq([recent, earlier])
    end
  end

  describe 'validations' do
    it 'requires that name is not blank' do
      course = build(:course, params.merge(name: nil))
      expect(course).not_to be_valid
      expect(course.errors[:name]).to contain_exactly('is required')

      course = build(:course, params.merge(name: ''))
      expect(course).not_to be_valid
      expect(course.errors[:name]).to contain_exactly('is required')

      course = build(:course, params.merge(name: '   '))
      expect(course).not_to be_valid
      expect(course.errors[:name]).to contain_exactly('is required')
    end

    it 'requires a school' do
      course = build(:course, params.merge(school_id: nil))
      expect(course).not_to be_valid
      expect(course.errors[:school_id]).to contain_exactly('must be a number')
      expect(course.errors[:school]).to contain_exactly('must exist')

      course = build(:course, params.merge(school_id: 'as'))
      expect(course).not_to be_valid
      expect(course.errors[:school_id]).to contain_exactly('must be a number')
      expect(course.errors[:school]).to contain_exactly('must exist')

      course = build(:course, params.merge(school_id: -1))
      expect(course).not_to be_valid
      expect(course.errors[:school_id]).to contain_exactly('must be greater than -1')
      expect(course.errors[:school]).to contain_exactly('must exist')

      course = build(:course, params.merge(school_id: 5.1))
      expect(course).not_to be_valid
      expect(course.errors[:school_id]).to contain_exactly('must be an integer')
      expect(course.errors[:school]).to contain_exactly('must exist')
    end

    it 'requires an owner' do
      course = build(:course, params.merge(owner_id: nil))
      expect(course).not_to be_valid
      expect(course.errors[:owner_id]).to contain_exactly('must be a number')
      expect(course.errors[:owner]).to contain_exactly('must exist')

      course = build(:course, params.merge(owner_id: 'as'))
      expect(course).not_to be_valid
      expect(course.errors[:owner_id]).to contain_exactly('must be a number')
      expect(course.errors[:owner]).to contain_exactly('must exist')

      course = build(:course, params.merge(owner_id: -1))
      expect(course).not_to be_valid
      expect(course.errors[:owner_id]).to contain_exactly('must be greater than 0')
      expect(course.errors[:owner]).to contain_exactly('must exist')

      course = build(:course, params.merge(owner_id: 5.1))
      expect(course).not_to be_valid
      expect(course.errors[:owner_id]).to contain_exactly('must be an integer')
      expect(course.errors[:owner]).to contain_exactly('must exist')
    end

    it 'requires a program' do
      course = build(:course, params.merge(program_id: nil))
      expect(course).not_to be_valid
      expect(course.errors[:program_id]).to contain_exactly('must be a number')
      expect(course.errors[:program]).to contain_exactly('must exist')

      course = build(:course, params.merge(program_id: 'as'))
      expect(course).not_to be_valid
      expect(course.errors[:program_id]).to contain_exactly('must be a number')
      expect(course.errors[:program]).to contain_exactly('must exist')

      course = build(:course, params.merge(program_id: -1))
      expect(course).not_to be_valid
      expect(course.errors[:program_id]).to contain_exactly('must be greater than 0')
      expect(course.errors[:program]).to contain_exactly('must exist')

      course = build(:course, params.merge(program_id: 5.1))
      expect(course).not_to be_valid
      expect(course.errors[:program_id]).to contain_exactly('must be an integer')
      expect(course.errors[:program]).to contain_exactly('must exist')
    end

    it 'requires a valid start date' do
      course = build(:course, params.merge(start_date: nil))
      expect(course).not_to be_valid
      expect(course.errors[:start_date]).to contain_exactly('is required.')

      course = build(:course, params.merge(start_date: -1))
      expect(course).not_to be_valid
      expect(course.errors[:start_date]).to contain_exactly('is required.')

      course = build(:course, params.merge(start_date: '01-15'))
      expect(course).not_to be_valid
      expect(course.errors[:start_date]).to contain_exactly('is required.')

      course = build(:course, params.merge(start_date: '2010-02-29'))
      expect(course).not_to be_valid
      expect(course.errors[:start_date]).to contain_exactly('is required.')

      course = create(:course, params.merge(start_date: '2011-01-15 15:00:00'))
      expect(course).to be_valid

      course = create(:course, params.merge(start_date: '2011-01-15'))
      expect(course).to be_valid

      course = create(:course, params.merge(start_date: Time.zone.parse('2010-01-24')))
      expect(course).to be_valid
    end

    it 'requires a valid end date' do
      course = build(:course, params.merge(end_date: nil))
      expect(course).not_to be_valid
      expect(course.errors[:end_date]).to contain_exactly('is required.')

      course = build(:course, params.merge(end_date: -1))
      expect(course).not_to be_valid
      expect(course.errors[:end_date]).to contain_exactly('is required.')

      course = build(:course, params.merge(end_date: '01-15'))
      expect(course).not_to be_valid
      expect(course.errors[:end_date]).to contain_exactly('is required.')

      course = build(
        :course,
        params.merge(
          allow_past_end_date: true,
          end_date: '2010-02-29',
          start_date: '2010-01-02'
        )
      )
      expect(course).not_to be_valid
      expect(course.errors[:end_date]).to contain_exactly('is required.')

      course = create(
        :course,
        params.merge(
          allow_past_end_date: true,
          end_date: '2011-01-15 15:00:00',
          start_date: '2010-01-02'
        )
      )
      expect(course).to be_valid

      course = create(
        :course,
        params.merge(
          allow_past_end_date: true,
          end_date: '2011-01-15',
          start_date: '2010-01-02'
        )
      )
      expect(course).to be_valid
    end

    it 'does not allow an end date more than 3 years in the future' do
      course = build(:course, end_date: 3.years.from_now + 1)
      expect(course).not_to be_valid
      expect(course.errors[:end_date]).to contain_exactly(
        'must not be more than 3 years from now'
      )
    end

    it 'prevents the end date coming before the start date' do
      Timecop.freeze(Date.new(2010)) do
        start_date_after_end_date = {
          start_date: '2011-12-31',
          end_date: '2010-01-01'
        }
        course = build(:course, params.merge(start_date_after_end_date))
        expect(course).not_to be_valid
        expect(course.errors[:start_date]).to contain_exactly(
          'must come before End date'
        )
      end
    end

    context 'with a course that has existing assignments,' do
      let(:course) do
        create(:course, start_date: 1.month.ago, end_date: 1.month.from_now)
      end
      let(:section) { create(:section, course: course) }
      let(:first_due_date) { 2.weeks.ago.to_date }
      let(:last_due_date) { 2.weeks.from_now.to_date }

      before do
        create(:assignment, due_date: first_due_date, section: section)
        create(:assignment, due_date: last_due_date, section: section)
      end

      it 'allows setting the start date to the day the first assignment is due' do
        course.update(start_date: first_due_date)

        expect(course).to be_valid
      end

      it 'is invalid if the start date is after the first assignment date' do
        course.update(start_date: first_due_date + 1.day)
        course.valid?

        date_string = first_due_date.to_formatted_s(:slash_month_day_long_year)

        expect(course.errors[:start_date]).to eq(
          ["must be before the first assignment! (#{date_string})"]
        )
      end

      it 'allows setting the end date to the day the last assignment is due' do
        course.update(end_date: last_due_date)

        expect(course).to be_valid
      end

      it 'is invalid if the end date is before the last assignment is due' do
        course.update(end_date: last_due_date - 1.day)
        course.valid?

        date_string = last_due_date.to_formatted_s(:slash_month_day_long_year)

        expect(course.errors[:end_date]).to eq(
          ["must be after the last assignment! (#{date_string})"]
        )
      end
    end

    it 'requires that first_unit is not blank' do
      course = build(:course, first_unit_id: nil)
      course.valid?
      expect(course.errors[:first_unit_id]).to eq(['is required'])
    end

    it 'requires that last_unit is not blank' do
      course = build(:course, last_unit_id: nil)
      course.valid?
      expect(course.errors[:last_unit_id]).to eq(['is required'])
    end

    it 'prevents the last unit from coming before the first unit' do
      course = build(:course, first_unit: unit_2, last_unit: unit_1)
      course.valid?
      expect(course.errors[:last_unit]).to eq(['must come after First unit'])
    end

    it 'requires that both units be from the same program' do
      other_program = create(:program)
      other_program_unit = create(
        :unit,
        name: 'Lesson 7',
        rank: 2,
        program: other_program
      )
      course = build(:course, first_unit: unit_1, last_unit: other_program_unit)
      course.valid?
      expect(course.errors[:last_unit]).to eq(
        ['must be in the same program as First unit']
      )
    end

    context 'when the associated program does not support standard sets,' do
      it 'is invalid when a standard set is present' do
        standard_set_1 = create(:standard_set)

        course = build(:course, program: program, standard_set_ids: [standard_set_1.id])
        course.valid?

        expect(course.errors[:standard_sets]).to contain_exactly(
          'must be blank'
        )
      end

      it 'is valid when no standard set is present' do
        course = build(:course, params.merge(standard_set_ids: []))

        expect(course).to be_valid
      end
    end

    context 'when the associated program supports a list of standard sets,' do
      let(:standard_set_1) { create(:standard_set) }
      let(:standard_set_2) { create(:standard_set) }
      let(:standard_set_3) { create(:standard_set) }

      before do
        create(
          :program_config_with_standard_sets,
          program:,
          supported_standard_sets: [standard_set_1, standard_set_2, standard_set_3]
        )
      end

      it 'is valid when no standard set is present' do
        course = build(:course, params.merge(standard_set_ids: []))
        course.valid?

        expect(course).to be_valid
      end

      it 'returns an error when a standard set is not supported by the program' do
        standard_set_4 = create(:standard_set)
        course = build(
          :course,
          program:,
          standard_set_ids: [standard_set_1, standard_set_4].map(&:id)
        )
        course.valid?

        expect(course.errors[:standard_sets]).to contain_exactly(
          'must be supported by the program'
        )
      end

      it 'is valid when all the specified standard sets are supported by the program' do
        course = build(
          :course,
          params.merge(
            standard_set_ids: [standard_set_1, standard_set_2].map(&:id)
          )
        )

        expect(course).to be_valid
      end
    end
  end

  describe 'validate single_enterprise_section' do
    context 'when the course is enterprise' do
      subject(:course) { create(:enterprise_course) }

      let(:new_section) { build(:enterprise_section, course: nil) }

      context 'when the course does not have an enterprise section' do
        before { course.sections << new_section }

        it { expect(course).to be_valid }
      end

      context 'when the course already has an enterprise section' do
        before do
          create(:enterprise_section, course:)
          course.sections << new_section
        end

        it { expect(course).not_to be_valid }
      end
    end

    context 'when the course is not enterprise' do
      let(:new_section) { build(:section) }

      before { course.sections << new_section }

      context 'when the course does not have a section' do
        subject(:course) { create(:course) }

        it { expect(course).to be_valid }
      end

      context 'when the course already has a section' do
        subject(:course) { create(:course_with_section) }

        it { expect(course).to be_valid }
      end
    end
  end

  describe '#is_enterprise' do
    it 'sets is_enterprise to false by default' do
      course = described_class.new
      expect(course.is_enterprise).to be false
    end
  end

  it "should include Steppable" do
     expect(Course.new).to be_a_kind_of(Steppable)
  end

  describe "#activity_xml_filepaths_for_all_attempts" do
    context "when there is no sections" do
      let(:course){ create(:course) }

      it "returns an empty array" do
        expect(course.activity_xml_filepaths_for_all_attempts).to eq([])
      end
    end

    context "when there is a section" do
      it "returns an array of filepaths" do
        course = create(:course)
        section_1 = create(:section)
        course.sections = [section_1]
        section_1_xml_paths = ['section_1_xml_path_1', 'section_1_xml_path_2']
        allow(Attempt).to receive(:activity_xml_file_paths).and_return(section_1_xml_paths)
        expect(course.activity_xml_filepaths_for_all_attempts).to eq(section_1_xml_paths)
      end
    end
  end

  describe '.default_values' do
    it 'returns a hash with expected default values to build a course' do
      Timecop.freeze('2019-01-01') do
        start_date = Date.current
        end_date = start_date + 14.weeks

        expected_values = {
          draft: true,
          name: 'New course',
          start_date: start_date,
          end_date: end_date
        }
        expect(described_class.default_values).to eq expected_values
      end
      Timecop.return
    end
  end

  describe "#response_xml_filepaths_for_all_attempts" do
    context "when there is no sections" do
      let(:course){ create(:course) }

      it "returns an empty array" do
        expect(course.response_xml_filepaths_for_all_attempts).to eq([])
      end
    end

    context "when there is a section" do
      it "returns an array of filepaths", test_debt: true  do
        # course = create(:course)
        # section_1 = create(:section)
        # course.sections = [section_1]
        # section_1_xml_paths = ['section_1_xml_path_1', 'section_1_xml_path_2']
        # Attempt.stub(:response_xml_file_paths).and_return(section_1_xml_paths)
        # course.response_xml_filepaths_for_all_attempts.should == section_1_xml_paths
        skip "we don't use xml storage anymore, this must be changed"
      end
    end
  end

  describe "#steps" do
    it "should return the 4 steps of the course wizard" do
      expect(Course.new.steps).to eq(%w[course content gradebook summary])
    end
  end

  describe "#draft_expired?" do
    let(:course) { build_stubbed(:course) }
    it "is true when course's error list contains EXPIRED_MESSAGE" do
      course.errors.add(:base, Course::EXPIRED_MESSAGE)
      expect(course.draft_expired?).to be_truthy
    end

    it "is false when course's error list does not contain EXPIRED_MESSAGE" do
      expect(course.draft_expired?).to be_falsey
    end
  end

  describe '#sections_count' do
    context 'when some sections' do
      before do
        @course = create(:course)
        create(:section, :course => @course)
        create(:section, :course => @course)
      end

      it 'returns the number of sections' do
        expect(@course.sections_count).to eq(2)
      end
    end

    context 'when one section' do
      before do
        @course = create(:course)
        create(:section, :course => @course)
      end

      it 'returns 1' do
        expect(@course.sections_count).to eq(1)
      end
    end

    context 'when no sections' do
      before do
        @course = create(:course)
      end

      it 'returns 0' do
        expect(@course.sections_count).to be_zero
      end
    end
  end

  describe '#contains_unit?' do
    let(:program) { create(:program) }
    let(:last_unit) { create(:unit, rank: 6, program: program) }
    let(:first_unit) { create(:unit, rank: 3, program: program) }
    let(:course) do
      create(
        :course,
        first_unit: first_unit,
        last_unit: last_unit,
        program: program
      )
    end
    let(:current_events_unit) do
      build_stubbed(:current_events_unit, rank: 777, program: program)
    end

    it 'returns true when provided with a unit covered by the study plan' do
      middle_unit = create(:unit, rank: 4, program: program)
      expect(course.contains_unit?(first_unit)).to be_truthy
      expect(course.contains_unit?(last_unit)).to be_truthy
      expect(course.contains_unit?(middle_unit)).to be_truthy
    end

    it 'returns false when provided with a unit not covered by the study plan' do
      earlier_unit = create(:unit, rank: 2, program: program)
      later_unit = create(:unit, rank: 7, program: program)
      expect(course.contains_unit?(earlier_unit)).to be_falsey
      expect(course.contains_unit?(later_unit)).to be_falsey
    end

    context 'when there is a current event unit for the program' do
      it 'returns true when provided with that kind of unit' do
        # allow(program).to receive(:current_events_unit).and_return(current_events_unit)
        expect(course.contains_unit?(current_events_unit)).to be_truthy
      end
    end
  end

  describe "#owner" do
    let(:program) { create(:program) }

    it "returns an active owner of a course" do
      instructor = create(:instructor)
      course = build_stubbed(:course, program: program,
                                      owner: instructor)

      expect(course.owner).to eq(instructor)
    end

    it "returns an archived owner of a course" do
      instructor = create(:instructor, archived: 1)
      course = build_stubbed(:course, program: program,
                                      owner: instructor)

      expect(course.owner).to eq(instructor)
    end
  end

  describe "#units_covered" do
    it "returns the only units included in the study schedule" do
      @program = create(:program)
      @unit_1 = create(:unit, :program => @program, :rank => 1)
      @unit_2 = create(:unit, :program => @program, :rank => 2)
      @unit_3 = create(:unit, :program => @program, :rank => 3)
      @course = build_stubbed(:course, :program => @program,
                                      :first_unit_id => @unit_1.id,
                                      :last_unit_id => @unit_2.id)
      @section = build_stubbed(:section, :course => @course)
      expect(@course.units_covered).not_to include(@unit_3)
      expect(@course.units_covered).to eq([@unit_1, @unit_2])
    end
  end

  describe "#lessons_covered" do
    before(:each) do
      owner   = build_stubbed(:instructor)
      school  = build_stubbed(:school)
      @program = create(:program)
      @lesson_1 = create(:lesson, :rank => 1)
      @unit_1 = create(:unit, :program => @program, :rank => 1, :lessons => [@lesson_1])
      @lesson_2 = create(:lesson, :rank => 2)
      @unit_2 = create(:unit, :program => @program, :rank => 2, :lessons => [@lesson_2])
      @course = create(:course, :program => @program, :first_unit => @unit_1, :last_unit => @unit_2, :owner => owner, :school => school)
    end

    it "should return only lessons for units covered in the course" do
      lesson_3 = create(:lesson, :rank => 3)
      unit_3 = create(:unit, :program => @program, :rank => 3, :lessons => [lesson_3])

      expect(@course.lessons_covered).not_to include lesson_3
      expect(@course.lessons_covered).to eq([@lesson_1, @lesson_2])
    end

    it "should sort returned lessons by rank" do
      @lesson_1.update!(:rank => @lesson_2.rank + 1)
      expect(@course.lessons_covered).to eq([@lesson_1, @lesson_2])
    end
  end

  describe "#weeks_covered" do
    it "should return the weeks containing the course start and end dates and weeks in between" do
      owner   = build_stubbed(:instructor)
      school  = build_stubbed(:school)
      program = build_stubbed(:program)
      start_date = Date.today - 5
      end_date = Date.today + 9
      course = create(:course, :start_date => start_date, :end_date => end_date, :owner => owner, :school => school)
      weeks_covered = course.weeks_covered
      expect(weeks_covered).to eq([Week.week_containing(start_date), (Week.week_containing(start_date) + 7), Week.week_containing(end_date)])
    end
  end

  describe "#week_number" do
    before(:each) do
      @course = build_stubbed(:course, :start_date => Date.today, :end_date => 3.months.from_now )
    end

    it "should return the week number relative to date given" do
      expect(@course.week_number(Date.today)).to eq(1)
      expect(@course.week_number(9.weeks.from_now)).to eq(10)
    end

    it "should return nil if the date is outside the course span" do
      expect(@course.week_number(1.week.ago)).to be_nil
      expect(@course.week_number(4.months.from_now)).to be_nil
    end
  end

  describe ".find_archived" do
    it "finds archived courses" do
      program = build_stubbed(:program)
      school  = build_stubbed(:school)
      course_1 = create(:course, :is_archived => true, :program => program, :school => school)
      expect(Course.find_by_id(course_1.id)).to eq(nil)
      expect(Course.find_archived(course_1.id)).to eq(course_1)
    end
  end

  #TODO: optimize this. Seems like we don't need to generate all of this data for every test
  describe ".find_joinable_at_school" do
    context "when no program is specified," do
      before(:each) do
        program = build_stubbed(:program)
        instructor = build_stubbed(:instructor)
        @school = build_stubbed(:school)

        @course_1  = create(:course_with_section, :owner => instructor, :program => program, :school => @school)

        @section_1 = create(:section, :course => @course_1)

        @course_3  = create(:course_with_section, :owner => instructor, :program => program, :school => create(:school))

        @course_4  = create(:course_with_section, :owner => instructor, :program => program, :school => @school, :is_archived => true)

        @course_5  = create(:course, :owner => instructor, :program => program, :school => @school)
        @section_2 = create(:section, :course => @course_5, :is_archived => true)

        @course_6  = create(:course, :owner => instructor, :program => program, :school => @school)
        @section_3 = create(:section, :course => @course_6)
        @section_3.course.start_date = 12.months.ago
        @section_3.course.end_date = 6.months.ago
        @section_3.course.allow_past_end_date = true
        @section_3.course.save!

        @course_7  = create(:course_with_section, :owner => instructor, :program => program, :school => @school, :is_demo => true)

        @course_8  = create(:course_with_section, :owner => instructor,
                                                          :program => program,
                                                          :allow_past_end_date => true,
                                                          :school => @school,
                                                          :end_date => 4.days.ago)
        @course_9  = create(:course, :owner => instructor, :program => program, :school => @school)

        @results = Course.find_joinable_at_school(@school.id)
      end

      it "returns courses at the specified school" do
        expect(@results).to include(@course_1)
      end

      it "returns only one course entry for courses with multiple sections" do
        expect(@results.to_a.count(@course_1)).to eq(1)
      end

      it "does not return courses at other schools" do
        expect(@results).not_to include(@course_3)
      end

      it "does not return archived courses" do
        expect(@results).not_to include(@course_4)
      end

      it "does not return courses that have only sections that are archived" do
        expect(@results).not_to include(@course_5)
      end

      it "does not return courses that have only sections that are closed" do
        expect(@results).not_to include(@course_6)
      end

      it "does not return demo courses" do
        expect(@results).not_to include(@course_7)
      end

      it "does not return courses with end dates in the past" do
        expect(@results).not_to include(@course_8)
      end

      it "does not return courses with no sections" do
        expect(@results).not_to include(@course_9)
      end
    end

    context "when a program is specified," do
      it "returns only courses for a program if one is specified" do
        school = create(:school)
        program_1 = create(:program)
        program_2 = create(:program)
        instructor = build_stubbed(:instructor)
        course_1  = create(:course, :owner => instructor, :program => program_1, :school => school)
        create(:section, :course => course_1)

        course_2  = create(:course, :owner => instructor, :program => program_2, :school => school)
        create(:section, :course => course_2)

        results = Course.find_joinable_at_school(school.id, program_1.id)
        expect(results).to include course_1
        expect(results).not_to include course_2
      end
    end

  end

  describe '.find_school_courses' do
    before do
      program = create(:program)
      school_1 = create(:school)
      instructor = create(:instructor)
      @course_1 = create(
        :course_with_section,
        program: program,
        owner: instructor,
        school: school_1
      )
      @archived_course_1 = create(
        :course_with_section,
        program: program,
        owner: instructor,
        is_archived: true,
        school: school_1
      )
      @course_2 = create(
        :course_with_section,
        program: program,
        owner: instructor,
        school: create(:school)
      )
      @results = Course.find_school_courses([school_1])
    end

    it "returns courses at the specified school" do
      expect(@results).to include(@course_1)
    end

    it "does not return courses from other schools" do
      expect(@results).not_to include(@course_2)
    end

    it "does not return archived courses" do
      expect(@results).not_to include(@archived_course_1)
    end
  end

  describe "#closed?" do
    before(:each) do
      program = build_stubbed(:program)
      school  = build_stubbed(:school)
      instructor = build_stubbed(:instructor)
      @open_course    = create(:course, :school => school, :program => program, :owner => instructor, :end_date => 6.months.from_now)
      @closed_course  = create(:closed_course, :school => school, :program => program, :owner => instructor, :end_date => 3.days.ago)
    end

    it "should return true when the course end_date has passed" do
      expect(@closed_course.closed?).to be_truthy
    end

    it "should return false when the course end date is in the future" do
      expect(@open_course.closed?).to be_falsey
    end
  end

  describe "#validate_total_category_weights" do
    before(:each) do
      @course = build_stubbed(:course)
    end

    it "should not set errors if there are no categories" do
      @course.validate_total_category_weights
      expect(@course.errors).to be_empty
    end

    it "should not set errors if all category weights add up to 100%" do
      @course.categories.build(:name => 'label_1', :weighting_percent => 75)
      @course.categories.build(:name => 'label_2', :weighting_percent => 25)
      @course.validate_total_category_weights
      expect(@course.errors).to be_empty
    end

    it "should return false if all category weights add up to less than 100%" do
      @course.categories.build(:name => 'label_1', :weighting_percent => 75)
      @course.categories.build(:name => 'label_2', :weighting_percent => 20)
      @course.validate_total_category_weights
      expect(@course.errors).not_to be_empty
      expect(@course.errors[:base]).to include "Category weights must add up to 100%, currently 95%"
    end

    it "should return false if all category weights add up to more than 100%" do
      @course.categories.build(:name => 'label_1', :weighting_percent => 75)
      @course.categories.build(:name => 'label_2', :weighting_percent => 40)
      @course.validate_total_category_weights
      expect(@course.errors[:base]).to include "Category weights must add up to 100%, currently 115%"
    end
  end

  describe "#has_enrollments?" do
    let(:course) { create(:course) }
    let(:section) { create(:section, :course => course) }

    context "when there are sections" do
      it "returns true when there are enrolled students" do
        create(:enrollment, :user => build_stubbed(:student), :section => section)
        expect(course).to have_enrollments
      end

      it "returns false when there are no enrollments" do
        expect(course).not_to have_enrollments
      end
    end

    context "when there are no sections" do
      it "returns false" do
        expect(course).not_to have_enrollments
      end
    end
  end

  describe "#assignments?" do
    let!(:course) { create(:course) }
    let!(:category) { create(:category, :course => course) }

    it 'returns true when one of the course categories has assignments' do
      create(:assignment, :category => category)
      expect(course.reload.assignments?).to be_truthy
    end

    it 'returns false when none of the course categories have assignments' do
      expect(course.assignments?).to be_falsey
    end
  end

  describe "#archive" do
    let(:course) {  create(:course, :owner => create(:instructor))}
    context "when owner is archiving the course" do
      context "when course is current" do

        context "when course has no sections" do
          it "archive the course" do
            course.archive
            expect(course).to be_archived
          end

          it "archives the related categories" do
            category = create(:category)
            allow(course).to receive(:categories).and_return([category])
            course.archive
            expect(course).to be_archived
          end
        end

        context "when course has sections" do
          let!(:section) { build_stubbed(:section) }

          before(:each) do
            allow(section).to receive(:students).and_return([])
            allow(section).to receive(:archive)
            allow(section).to receive(:assignments).and_return([])
            allow(course).to receive(:sections).and_return([section])
          end

          context "when there are sections with no assignments or students" do
            it "archives the course" do
              course.archive
              expect(course.errors.full_messages).to eq([])
              expect(course).to be_archived
            end

            it "archives the related sections" do
              expect(section).to receive(:archive)
              course.archive
            end
          end

          context "with an instructor team" do
            it "archives the related sections" do
              expect(section).to receive(:archive)
              course.archive
            end
          end

          context "when there are sections with assignment(s)" do
            it "does not archive the course" do
              section = create(:section)
              allow(section).to receive(:students).and_return([])
              allow(section).to receive(:assignments).and_return(['assignment'])
              allow(course).to receive(:sections).and_return([section])
              course.archive
              expect(course.errors.full_messages).to eq(["Course <b>#{course.name}</b> has section(s) with assignment(s). You must delete each section individually in its Edit Section page."])
              expect(course.is_archived).to be_falsey
            end
          end

          context "when there are sections with student(s)" do
            it "does not archive the course" do
              section = create(:section)
              allow(section).to receive(:students).and_return(['student'])
              allow(course).to receive(:sections).and_return([section])
              course.archive
              expect(course.errors.full_messages).to eq(["Course <b>#{course.name}</b> has section(s) with student(s). You must delete each section individually in its Edit Section page."])
              expect(course).not_to be_archived
            end
          end
        end
      end

      context 'when the course is closed,' do
        let(:course) { create(:closed_course) }

        it 'archives the course' do
          course.allow_past_end_date = false

          course.archive

          expect(course).to be_archived
          expect(course.errors).to be_empty
        end
      end

      context 'when the course is editable,' do
        let(:course) { create(:editable_course) }

        it 'archives the course' do
          course.allow_past_end_date = false

          course.archive

          expect(course.reload).to be_archived
          expect(course.errors).to be_empty
        end
      end
    end
  end

  describe "#prospective_additional_instructors" do
    let(:school) { build_stubbed(:school) }
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course, :program => program, :school => school) }

    before do
      allow(school).to receive(:active_instructors_with_program_access)
    end

    it "should look up additional instructor on school" do
      expect(school).to receive(:active_instructors_with_program_access).with(program)
      course.prospective_additional_instructors
    end
  end

  describe "#section_class_days_vary?" do
    before(:each) do
      @course = create(:course)
    end

    context "when the course has no sections" do
      it "should return false" do
        expect(@course.section_class_days_vary?).to be_falsey
      end
    end

    context "when the course has one section" do
      before(:each) do
        create(:section, :course => @course)
      end

      it "should return false" do
        expect(@course.section_class_days_vary?).to be_falsey
      end
    end

    context "when the course has multiple sections" do
      before(:each) do
        create(:section, :course => @course)
        create(:section, :course => @course)
      end

      context "when all sections have classes on the same days" do
        before(:each) do
          @course.sections.first.class_days = '1,2,4'
          @course.sections.last.class_days = '2,4,1,2'
        end

        it "should return false" do
          expect(@course.section_class_days_vary?).to be_falsey
        end
      end

      context "when any two sections have classes on different days" do
        before(:each) do
          @course.sections.first.class_days = '1,2,4'
          @course.sections.last.class_days = '2,4,1,2'
          create(:section, :course => @course, :class_days => '1,2,3,4')
        end

        it "should return true" do
          expect(@course.section_class_days_vary?).to be_truthy
        end
      end
    end
  end

  describe '#editable?' do
    it 'is true if the end date is within the past month' do
      course = build_stubbed(:course, :end_date => Date.tomorrow)
      expect(course).to be_editable
    end

    it 'is true if the end date is one month from now' do
      course = build_stubbed(:course, :end_date => Date.today + 1.month)
      expect(course).to be_editable
    end

    it 'is true if the end date was 1 month ago' do
      course = build_stubbed(:course, :end_date => Date.today - 1.month)
      expect(course).to be_editable
    end

    it 'is false if the end date was over a month ago' do
      course = build_stubbed(:course, :end_date => Time.zone.now.to_date - 35.days)
      expect(course).not_to be_editable
    end
  end

  describe "#covers_all_program_units?" do
    let!(:program) { create(:program) }
    let!(:unit_1) { create(:unit, :rank => 1, :program => program) }
    let!(:unit_2) { create(:unit, :rank => 2, :program => program) }
    let!(:unit_3) { create(:unit, :rank => 3, :program => program) }

    it "is true when course's units are the same of the course's program units" do
      course = create(:course, :program => program, :first_unit => program.units.first, :last_unit => program.units.last )
      expect(course.covers_all_program_units?).to be_truthy
    end

    it "is false when course's units are not the same of the course's program units" do
      course = create(:course, :program => program, :first_unit => program.units.second, :last_unit => program.units.last )
      expect(course.covers_all_program_units?).to be_falsey
    end
  end

  describe "#possible_video_languages" do
    let(:program) { create(:program) }
    let(:course) { create(:course, program: program) }
    let(:possible_video_languages) { course.possible_video_languages }

    context "with a course in a program with language name of Swahili," do
      before do
        allow(program).to receive(:language_name).and_return('Swahili')
      end

      it "returns a foreign option labeled Swahili as the first option" do
        expect(possible_video_languages.first).to eq(['Swahili', 'foreign'])
      end

      it "returns a foreign_and_english option labeled Swahili and English as the second option" do
        expect(possible_video_languages[1]).to eq(['Swahili and English', 'foreign_and_english'])
      end

      it "returns a none option labeled None as the last option" do
        expect(possible_video_languages.last).to eq(['None', 'none'])
      end
    end

    context 'with an English program' do
      it 'returns only the none and English options' do
        program.update!(language_code: 'en')
        expect(possible_video_languages).to eq([ ['English', 'foreign'], ['None', 'none'] ])
      end
    end
  end

  describe '#chat_disabled?' do
    it 'is true when chat_level is "disabled"' do
      course = build(:course, chat_level: 'disabled')
      expect(course).to be_chat_disabled
    end

    it 'is false when chat_level is "partner_chat"' do
      course = build(:course, chat_level: 'partner_chat')
      expect(course).not_to be_chat_disabled
    end

    it 'is false when chat level is "partner_chat_and_live_chat"' do
      course = build(:course, chat_level: 'partner_chat_and_live_chat')
      expect(course).not_to be_chat_disabled
    end
  end

  describe '#chat_enabled?' do
    it 'is false when chat_level is "disabled"' do
      course = build(:course, chat_level: 'disabled')
      expect(course).not_to be_chat_enabled
    end

    it 'is true when chat_level is "partner_chat"' do
      course = build(:course, chat_level: 'partner_chat')
      expect(course).to be_chat_enabled
    end

    it 'is true when chat level is "partner_chat_and_live_chat"' do
      course = build(:course, chat_level: 'partner_chat_and_live_chat')
      expect(course).to be_chat_enabled
    end
  end

  describe '#live_chat_enabled?' do
    let(:course) { build_stubbed(:course) }

    describe 'when chat_level is "partner_chat_and_live_chat"' do
      it 'returns true' do
        allow(course).to receive(:chat_level).and_return('partner_chat_and_live_chat')
        expect(course.live_chat_enabled?).to be_truthy
      end
    end

    describe 'when chat_level is not "partner_chat_and_live_chat"' do
      it 'returns false' do
        allow(course).to receive(:chat_level).and_return('partner_chat')
        expect(course.live_chat_enabled?).to be_falsey
      end
    end
  end

  describe '#partner_chat_enabled?' do
    let(:course) { build_stubbed(:course) }

    describe 'when chat_level is "partner_chat_and_live_chat"' do
      it 'returns true' do
        allow(course).to receive(:chat_level).and_return('partner_chat_and_live_chat')
        expect(course.partner_chat_enabled?).to be_truthy
      end
    end

    describe 'when chat_level is "partner_chat"' do
      it 'returns true' do
        allow(course).to receive(:chat_level).and_return('partner_chat')
        expect(course.partner_chat_enabled?).to be_truthy
      end
    end

    describe 'when chat_level is not "partner_chat_and_live_chat"' do
      it 'returns false' do
        allow(course).to receive(:chat_level).and_return('disabled')
        expect(course.partner_chat_enabled?).to be_falsey
      end
    end
  end

  describe '#create_library' do
    let(:program) { create(:program) }
    let(:unit) { create(:unit_with_lessons, :program => program) }
    let!(:activity_1) { create(:activity, :lesson_id => unit.lessons.first.id) }
    let!(:activity_2) { create(:activity, :lesson_id => unit.lessons.first.id) }
    let!(:created_activity) { create(:activity, instructor_revision_id: 100) }
    let!(:created_activity_to_share) { create(:activity, instructor_revision_id: 100) }
    let!(:shared_activity) { create(:activity, instructor_revision_id: 100) }

    context 'with a given course' do
      let(:existing_course) { create(:course, :program => program) }

      context 'when copying instructor created activities from existing course' do
        let(:copy_created_activities_from_previous_course){ true }

        it 'copies the course library for instructor created activities
            of the given course object' do
          create(:course_library_activity, course: existing_course, activity: activity_1, hidden: false)
          create(:course_library_activity, course: existing_course, activity: activity_2, hidden: true)
          create(:course_library_activity, course: existing_course, activity: created_activity, hidden: false)

          new_course = create( :course,
                                :name => 'Jorge',
                                :program => program,
                                :course_library_from => existing_course,
                                :copy_created_activities_from_previous_course => copy_created_activities_from_previous_course)
          results = CourseLibraryActivity.by_course(new_course).map(&:activity)
          expect(results).not_to include activity_1
          expect(results).not_to include activity_2
          expect(results).to include created_activity
        end
      end

      context 'when copying shared instructor created activities from existing course' do
        let(:copy_shared_activities_from_previous_course){ true }

        it 'copies the course library for shared instructor created activities
            of the given course object' do
          create(:course_library_activity, course: existing_course, activity: activity_1, hidden: false)
          create(:course_library_activity, course: existing_course, activity: activity_2, hidden: true)
          create(:course_library_activity, course: existing_course, activity: created_activity, hidden: false)
          create(:course_library_activity, course: existing_course, activity: shared_activity, hidden: false)
          create(:shared_library_activity,
                 source_activity_id: created_activity_to_share.id,
                 activity_id: shared_activity.id,
                 school_id: existing_course.school_id,
                 is_shared: true)

          new_course = create(:course,
                              name: 'Jorge',
                              program: program,
                              course_library_from: existing_course,
                              copy_shared_activities_from_previous_course: copy_shared_activities_from_previous_course)
          results = CourseLibraryActivity.by_course(new_course).map(&:activity)
          expect(results).not_to include created_activity
          expect(results).to include shared_activity
        end
      end

      context 'when avoid copying instructor created activities from previous course' do
        let(:copy_created_activities_from_previous_course){ false }

        it 'does not copy the course library for instructor created activities
            of the given course object' do
          create(:course_library_activity, course: existing_course, activity: activity_1, hidden: false)
          create(:course_library_activity, course: existing_course, activity: activity_2, hidden: true)
          create(:course_library_activity, course: existing_course, activity: created_activity, hidden: false)
          new_course = create( :course,
                                :name => 'Jorge',
                                :program => program,
                                :course_library_from => existing_course,
                                :copy_created_activities_from_previous_course => copy_created_activities_from_previous_course)
          results = CourseLibraryActivity.by_course(new_course).map(&:activity)
          expect(results).to eq([])
        end

      end
    end
  end

  describe '#sections_with_assignments' do
    it 'returns an array of sections with assignments' do
      course = create(:course)
      assignment = create(:assignment)
      section_1 = create(:section, course: course, assignments: [assignment])
      section_2 = create(:section, course: course, assignments: [])
      expect(course.sections_with_assignments).to eq([section_1])
    end
  end

  describe '.find_guid' do
    it 'returns the guid of a course given an id' do
      course = create(:course)
      expect(Course.find_guid(course.id)).to eql(course.guid)
    end
  end

  describe ".by_guid" do
    it 'returns course that matches specified guid' do
      new_course = create(:course)
      expect(Course.by_guid(new_course.guid)).to eql(new_course)
    end
  end

  describe '#gradebook_analytics_enabled?' do
    it 'delegates to its school' do
      school = create(:school)
      course = create(:course, school: school)
      allow(school).to receive(:gradebook_analytics_enabled?)

      course.gradebook_analytics_enabled?
      expect(school).to have_received(:gradebook_analytics_enabled?)
    end
  end

  describe '#one_roster_linked?' do
    let(:course) { section.course }
    let(:section) { create(:section_with_course) }

    it 'returns true if at least one section of the course is one_roster_linked' do
      create(:one_roster_linked_section, section: section)
      expect(course).to be_one_roster_linked
    end

    it 'returns false if none of the sections of the course is one_roster_linked' do
      expect(course).not_to be_one_roster_linked
    end

    it 'returns false if the course has no sections' do
      course_with_no_sections = create(:course)
      expect(course_with_no_sections).not_to be_one_roster_linked
    end
  end

  describe '#has_one_roster_academic_session?' do
    let(:course) { section.course }
    let(:section) { create(:section_with_course) }
    let(:one_roster_linked_section) { create(:one_roster_linked_section, section: section) }

    context 'with a one_roster_linked_section' do
      it 'returns true if the section has academic session' do
        one_roster_linked_section.update(academic_session: 'some_id')
        expect(course).to have_one_roster_academic_session
      end

      it 'returns false if the section does not have academic session' do
        one_roster_linked_section.update(academic_session: nil)
        expect(course).not_to have_one_roster_academic_session
      end
    end

    it 'returns false if there are no one_roster_linked_sections' do
      expect(course).not_to have_one_roster_academic_session
    end

    it 'returns false if the course has no sections' do
      course_with_no_sections = create(:course)
      expect(course_with_no_sections).not_to have_one_roster_academic_session
    end
  end

  describe '#hide_from_instructor_dash' do
    let(:admin) { create(:institution_admin) }
    let(:co_instructor) { create(:instructor) }
    let!(:course) { create(:course, owner: admin) }
    let!(:section_1) { create(:section, course: course, instructor: admin) }
    let!(:section_2) { create(:section, course: course, instructor: admin) }
    let!(:co_instructor_record) { create(:section_co_instructor,
                                        section: section_1,
                                        instructor: co_instructor) }

    context 'when an admin hides a course from their dashboard' do
      it 'sets the hide flag on section instructor record for the course owner to true' do
        course.hide_from_instructor_dash(true)
        instructor_record_section_1 = SectionInstructor.where(section: section_1,
                                                              user_id: admin.id,
                                                              role: 'Instructor')
                                                       .first

        instructor_record_section_2 = SectionInstructor.where(section: section_2,
                                                              user_id: admin.id,
                                                              role: 'Instructor')
                                                       .first

        co_instructor_record = SectionInstructor.where(section: section_1,
                                                       user_id: co_instructor.id,
                                                       role: 'Co-instructor')
                                                .first

        expect(instructor_record_section_1.hide_from_instructor_dashboard).to be(true)
        expect(instructor_record_section_2.hide_from_instructor_dashboard).to be(true)
        expect(co_instructor_record.hide_from_instructor_dashboard).to be(false)
      end
    end

    context 'when an admin un-hides a course from their dashboard' do
      it 'sets the hide flag on section instructor record for the course owner to false' do
        SectionInstructor.where(section: [section_1, section_2],
                                user_id: admin.id,
                                role: 'Instructor')
          .update_all(hide_from_instructor_dashboard: true)
        course.hide_from_instructor_dash(false)
        instructor_record_section_1 = SectionInstructor.where(section: section_1,
                                                              user_id: admin.id,
                                                              role: 'Instructor')
                                                       .first

        instructor_record_section_2 = SectionInstructor.where(section: section_2,
                                                              user_id: admin.id,
                                                              role: 'Instructor')
                                                       .first

        expect(instructor_record_section_1.hide_from_instructor_dashboard).to be(false)
        expect(instructor_record_section_2.hide_from_instructor_dashboard).to be(false)
      end
    end
  end

  describe '#start_end_date' do
    let(:course) { create(:course) }

    it 'returns a string formatted start and end date for the course' do
      result = course.start_date.strftime('%-m/%-d/%Y') + ' - ' + course.end_date.strftime('%-m/%-d/%Y')
      expect(course.start_end_date).to eql(result)
    end

    it 'formats the string differently if format is provided' do
      format = '%m/%d/%YY'
      result = course.start_date.strftime(format) + ' - ' + course.end_date.strftime(format)
      expect(course.start_end_date(format)).to eql(result)
    end
  end

  describe '#individually_assignable_enabled?' do
    let(:course) { create(:course) }
    let(:section) { create(:section, course: course) }
    let!(:assignment_one) { create(:assignment, section: section,
                                                individually_assignable: true) }
    let!(:assignment_two) { create(:assignment, section: section,
                                                individually_assignable: false) }

    it 'is true when there is at least one individual assignment' do
      expect(course.has_individual_assignments?).to be true
    end

    it 'is false when there is no individual assignment' do
      assignment_one.update!(individually_assignable: false)
      assignment_one.reload
      expect(course.has_individual_assignments?).to be false
    end
  end

  describe '#lti_roster_linked?' do
    let(:course) { section.course }
    let(:section) { create(:section_with_course) }

    it 'returns true if at least one section of the course is lti_roster_linked' do
      lti_rostering_instructor = create(:lti_rostering_instructor)
      create(:lti_rostering_user_link, user: lti_rostering_instructor)
      lti_rostering_section = create(:section_with_course, instructor: lti_rostering_instructor)
      create(:lti_context_link, section: lti_rostering_section)
      expect(lti_rostering_section.course).to be_lti_roster_linked
    end

    it 'returns false if none of the sections of the course is lti_roster_linked' do
      expect(course).not_to be_lti_roster_linked
    end

    it 'returns false if the course has no sections' do
      course_with_no_sections = create(:course)
      expect(course_with_no_sections).not_to be_lti_roster_linked
    end
  end

  describe '#autoroster_linked?' do
    let(:course) { section.course }
    let(:section) { create(:section_with_course) }

    it 'returns true if at least one section of the course is lti_roster_linked?' do
      lti_rostering_instructor = create(:lti_rostering_instructor)
      create(:lti_rostering_user_link, user: lti_rostering_instructor)
      lti_rostering_section = create(:section_with_course, instructor: lti_rostering_instructor)
      create(:lti_context_link, section: lti_rostering_section)
      expect(lti_rostering_section.course).to be_autorostering_linked
    end

    it 'returns true if at least one section of the course is one__roster_linked?' do
      create(:one_roster_linked_section, section: section)
      expect(course).to be_autorostering_linked
    end

    it 'returns false if none of the sections of the course is autorostering_linked?' do
      expect(course).not_to be_autorostering_linked
    end

    it 'returns false if the course has no sections' do
      course_with_no_sections = create(:course)
      expect(course_with_no_sections).not_to be_autorostering_linked
    end
  end
end
