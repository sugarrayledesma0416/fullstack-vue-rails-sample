describe CalendarHelper do
  include described_class

  let(:instructor) { build_stubbed(:instructor) }
  let(:student) { build_stubbed(:student) }
  let(:program) { build_stubbed(:program) }
  let(:section) { build_stubbed(:section) }

  let(:single_item_day) do
    OpenStruct.new(announcement_count: 1, id: 1)
  end

  let(:multiple_item_day) do
    OpenStruct.new(announcement_count: 3)
  end

  before do
    allow(helper).to receive(:current_program).and_return(program)
    allow(helper).to receive(:current_section).and_return(section)
  end

  describe '#user_announcement_link' do
    it 'returns a link to the instructor announcements index when current ' \
       'user is an instructor' do
      allow(helper).to receive(:current_user).and_return(instructor)

      expect(helper.user_announcement_link(single_item_day)).to have_link(
        'Announcement: 1',
        href: instructor_announcements_path(program_id: program.id)
      )
    end

    context 'when current user is a student,' do
      before do
        allow(helper).to receive(:current_user).and_return(student)
      end

      context 'with a non-Supersite Junior program,' do
        before do
          allow(helper).to receive(:supersite_junior?).and_return(false)
        end

        it 'returns a link to the announcement show page when there is' \
           'only one announcement' do
          expect(helper.user_announcement_link(single_item_day)).to have_link(
            'Announcement: 1',
            href: section_announcement_path(id: 1, section_id: section.id)
          )
        end

        it "returns a link to the student's announcement index when there " \
           'is more than one announcement' do
          expect(helper.user_announcement_link(multiple_item_day)).to have_link(
            'Announcements: 3',
            href: section_announcements_path(section_id: section.id)
          )
        end
      end

      context 'with a Supersite Junior program,' do
        before do
          allow(helper).to receive(:supersite_junior?).and_return(true)
        end

        it 'returns a link to the Supersite Junior announcement show page ' \
           'when there is only one announcement' do
          expect(helper.user_announcement_link(single_item_day)).to have_link(
            'Announcement: 1',
            href: jr_section_announcement_path(id: 1, section_id: section.id)
          )
        end

        it 'returns a link to the Supersite Junior Grown-ups dashboard ' \
           'when there is more than one announcement' do
          expect(helper.user_announcement_link(multiple_item_day)).to have_link(
            'Announcements: 3',
            href: jr_section_grownups_path(section_id: section.id)
          )
        end
      end
    end
  end

  describe '#announcement_link_path' do
    it 'returns the instructor announcements index path when user is an ' \
       'instructor' do
      allow(helper).to receive(:current_user).and_return(instructor)

      expect(helper.announcement_link_path(single_item_day)).to eq(
        instructor_announcements_path(program)
      )
    end

    context 'when current user is a student,' do
      before do
        allow(helper).to receive(:current_user).and_return(student)
      end

      context 'with a non-Supersite Junior program,' do
        before do
          allow(helper).to receive(:supersite_junior?).and_return(false)
        end

        it 'returns the announcement show path when there is only one ' \
           'announcement' do
          expect(helper.announcement_link_path(single_item_day)).to eq(
            section_announcement_path(id: 1, section_id: section.id)
          )
        end

        it 'returns the student announcements index path when there ' \
           'is more than one announcement' do
          expect(helper.announcement_link_path(multiple_item_day)).to eq(
            section_announcements_path(section_id: section.id)
          )
        end
      end

      context 'with a Supersite Junior program,' do
        before do
          allow(helper).to receive(:supersite_junior?).and_return(true)
        end

        it 'returns a link to the Supersite Junior announcement show page ' \
           'when there is only one announcement' do
          expect(helper.announcement_link_path(single_item_day)).to eq(
            jr_section_announcement_path(id: 1, section_id: section.id)
          )
        end

        it 'returns a link to the Supersite Junior Grown-ups dashboard ' \
           'when there is more than one announcement' do
          expect(helper.announcement_link_path(multiple_item_day)).to eq(
            jr_section_grownups_path(section_id: section.id)
          )
        end
      end
    end
  end
end
