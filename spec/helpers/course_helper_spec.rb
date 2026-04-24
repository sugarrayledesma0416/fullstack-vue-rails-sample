describe CourseHelper do
  describe('#format_current_school_style') do
    it 'returns display:block when params are equal' do
      expect(helper.format_current_school_style(1, 1)).to eql 'display:block;'
    end

    it 'returns display:none when params are not equal' do
      expect(helper.format_current_school_style(1, 2)).to eql 'display:none;'
    end
  end

  describe('#format_dashboard_selected_course') do
    before(:each) do
      @course_1 = build_stubbed(:course)
      @course_2 = build_stubbed(:course)
      @courses = [@course_1, @course_2]
      @section_1 = build_stubbed(:section)
      @section_2 = build_stubbed(:section)
      @sections = [@section_1, @section_2]
    end

    it "returns an empty string when focus is on another course" do
      focus = double(Focus, :course => @course_1, :sections => @sections, :students => [], :type => 'course')
      expect(helper.format_dashboard_selected_course(focus, @courses, @course_2)).to eql ''
    end

    it "returns 'expanded' when focus is the active course" do
      focus = double(Focus, :course => @course_1, :sections => @sections, :students => [], :type => 'course')
      expect(helper.format_dashboard_selected_course(focus, @courses, @course_1)).to eql 'expanded'
    end
  end

  describe('#format_dashboard_selected_section') do
    before(:each) do
      @course = build_stubbed(:course)
      @section_1 = build_stubbed(:section)
      @section_2 = build_stubbed(:section)
      @section_3 = build_stubbed(:section)
      @sections = [@section_1, @section_2]
    end

    it 'returns an empty string when focus is a course' do
      focus = double(Focus, :course => @course, :sections => @sections, :students => [], :type => 'course')
      allow(Focus).to receive(:new).and_return(@focus)
      allow(focus).to receive(:section).and_return(@section_1)
      expect(helper.format_dashboard_selected_section(focus, @sections, @section_1)).to eql ''
      expect(helper.format_dashboard_selected_section(focus, @sections, @section_2)).to eql ''
    end

    it 'returns an empty string when focus is on another section' do
      focus = double(Focus, :course => @course, :sections => [@section_1], :students => [], :type => 'section')
      allow(Focus).to receive(:new).and_return(@focus)
      allow(focus).to receive(:section).and_return(@section_1)
      expect(helper.format_dashboard_selected_section(focus, [@section_2, @section_3], @section_2)).to eql ''
    end

    it "returns 'expanded' when there is no focus and there is only 1 section in sections" do
      focus = double(Focus, :course => @course, :sections => [@section_1], :students => [], :type => 'section')
      allow(Focus).to receive(:new).and_return(@focus)
      allow(focus).to receive(:section).and_return(@section_1)
      expect(helper.format_dashboard_selected_section(focus, [@section_2], @section_2)).to eql 'expanded'
    end

    it "returns 'expanded' when focus is the active section" do
      focus = double(Focus, :course => @course, :sections => [@section_2], :students => [], :type => 'section')
      allow(Focus).to receive(:new).and_return(@focus)
      allow(focus).to receive(:section).and_return(@section_2)
      expect(helper.format_dashboard_selected_section(focus, [@section_2], @section_2)).to eql 'expanded'
    end
  end

  describe '#format_instructor_last_names' do
    it 'returns blank when section is nil' do
      expect(helper.format_instructor_last_names(nil)).to be_blank
    end

    context 'when there is only one instructor in the team' do
      it "returns last name in span with 'single' class" do
        section = build_stubbed(:section)
        instructor_1 = build_stubbed(:instructor)
        expected_name = HTMLEntities.new.encode(instructor_1.last_name, :decimal)
        expected_output = "<span class=\"single\"> #{expected_name}</span>"
        allow(section).to receive(:instructors).and_return([instructor_1])
        expect(helper.format_instructor_last_names(section)).to eql(expected_output)
      end
    end

    context 'when there are mulitple instructors in the team' do
      it "returns last names in spans with 'multiple' class" do
        section = build_stubbed(:section)
        instructor_1 = build_stubbed(:instructor)
        instructor_2 = build_stubbed(:instructor)
        expected_name_1 = HTMLEntities.new.encode(instructor_1.last_name, :decimal)
        expected_name_2 = HTMLEntities.new.encode(instructor_2.last_name, :decimal)
        expected_output = "<span class=\"multiple\"> #{expected_name_1}</span><span class=\"multiple\"> #{expected_name_2}</span>"
        allow(section).to receive(:instructors).and_return([instructor_1, instructor_2])
        expect(helper.format_instructor_last_names(section)).to eql(expected_output)
      end
    end
  end

  describe '#format_previous_course_index' do
    let(:course) { double(Course, :id => nil) }

    context 'when course does not have an id' do
      it "returns 'default' index when course name is 'New course name'" do
        allow(course).to receive(:name).and_return('New course name')
        expect(helper.format_previous_course_index(course)).to eq('default')
      end

      it "returns 'basic' index when course name is 'Basic course name'" do
        allow(course).to receive(:name).and_return('Basic course name')
        expect(helper.format_previous_course_index(course)).to eq('basic')
      end
    end

    it 'returns course id when course has an id' do
      allow(course).to receive(:id).and_return(1)
      expect(helper.format_previous_course_index(course)).to eq(1)
    end
  end

end
