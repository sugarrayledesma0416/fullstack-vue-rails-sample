# coding: utf-8
describe ApplicationHelper do
  include ApplicationHelper
  include MediaItemsHelper

  describe '#disabled_individual_assigning_reason' do
    let(:assistant_role_policy) { instance_double(AssistantRolePolicy) }

    before do
      allow(helper).to receive(:assistant_role_policy)
        .and_return(assistant_role_policy)
    end

    it 'returns a message when the user is an assistant' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(true)

      expect(helper.disabled_individual_assigning_reason(nil)).to eq(
        'Individual Assigning is not available to Assistants'
      )
    end

    context 'when user is not an assistant,' do
      before do
        allow(assistant_role_policy).to receive(:is_assistant?).and_return(false)
      end

      context 'when course argument is not nil,' do
        it 'returns a message if specified course does not allow individual ' \
           'assigning' do
          course = build(:course, allow_individual_assign: false)

          expect(helper.disabled_individual_assigning_reason(course)).to eq(
            'You have not enabled Individual Assigning for this course'
          )
        end

        it 'returns nil if specified course allows individual assigning' do
          course = build(:course, allow_individual_assign: true)

          expect(helper.disabled_individual_assigning_reason(course)).to be_nil
        end
      end

      context 'when course argument is nil,' do
        it 'returns a message if specified presenter is nil' do
          expect(helper.disabled_individual_assigning_reason(nil, nil)).to eq(
            "You currently don't have a course for this program"
          )
        end

        it 'returns a message if specified presenter has no ' \
           'open_courses_by_program method' do
          presenter = instance_double(StudentDashboardPresenter)

          expect(
            helper.disabled_individual_assigning_reason(nil, presenter)
          ).to eq("You currently don't have a course for this program")
        end

        context 'when the specified presenter has an open_courses_by_program ' \
                'method,' do
          let(:presenter) { instance_double(InstructorDashboardPresenter) }

          it 'returns a message when there are no open courses' do
            allow(presenter).to receive(:open_courses_by_program)
              .and_return([])

            expect(
              helper.disabled_individual_assigning_reason(nil, presenter)
            ).to eq("You currently don't have a course for this program")
          end

          it 'returns nil if there are open courses' do
            allow(presenter).to receive(:open_courses_by_program)
              .and_return([build(:course)])

            expect(
              helper.disabled_individual_assigning_reason(nil, presenter)
            ).to be_nil
          end
        end
      end
    end
  end

  describe '#disabled_assignment_reorder_reason' do
    let(:assistant_role_policy) { instance_double(AssistantRolePolicy) }

    before do
      allow(helper).to receive(:assistant_role_policy)
        .and_return(assistant_role_policy)
    end

    it 'returns a message when the user is an assistant' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(true)

      expect(helper.disabled_assignment_reorder_reason(nil)).to eq(
        'Assignment Reordering is not available to Assistants'
      )
    end

    context 'when user is not an assistant,' do
      before do
        allow(assistant_role_policy).to receive(:is_assistant?).and_return(false)
        allow(helper).to receive(:current_user).and_return(build_stubbed(:instructor))
      end

      context 'when course argument is not nil,' do
        it 'returns a message if specified course does not have any sections' do
          course = build(:course)

          expect(helper.disabled_assignment_reorder_reason(course)).to eq(
            "You currently don't have any sections for this course"
          )
        end

        it 'returns nil if specified course has a section' do
          instructor = build_stubbed(:instructor)
          course = build(:course, owner: instructor)
          section = build(:section, course: course, instructor: instructor)
          allow(course).to receive(:sections_by_instructor).and_return([section])
          allow(helper).to receive(:current_user).and_return(instructor)

          expect(helper.disabled_assignment_reorder_reason(course)).to be_nil
        end
      end

      context 'when course argument is nil,' do
        it 'returns a message if specified presenter is nil' do
          expect(helper.disabled_assignment_reorder_reason(nil, nil)).to eq(
            "You currently don't have a course for this program"
          )
        end

        it 'returns a message if specified presenter has no ' \
           'open_courses_by_program method' do
          presenter = instance_double(StudentDashboardPresenter)

          expect(
            helper.disabled_assignment_reorder_reason(nil, presenter)
          ).to eq("You currently don't have a course for this program")
        end

        context 'when the specified presenter has an open_courses_by_program ' \
                'method,' do
          let(:presenter) { instance_double(InstructorDashboardPresenter) }

          it 'returns a message when there are no open courses' do
            allow(presenter).to receive(:open_courses_by_program)
              .and_return([])

            expect(
              helper.disabled_assignment_reorder_reason(nil, presenter)
            ).to eq("You currently don't have a course for this program")
          end

          it 'returns nil if there are open courses' do
            allow(presenter).to receive(:open_courses_by_program)
              .and_return([build(:course)])

            expect(
              helper.disabled_assignment_reorder_reason(nil, presenter)
            ).to be_nil
          end
        end
      end
    end
  end

  describe '#disabled_standards_based_assigning_reason' do
    let(:assistant_role_policy) { instance_double(AssistantRolePolicy) }
    let(:program) { create(:program) }
    let(:instructor) { create(:instructor) }
    let(:co_instructor) { create(:instructor) }
    let(:course_with_section) { create(:course_with_section, owner: instructor, program: program) }

    before do
      allow(helper).to receive(:assistant_role_policy)
        .and_return(assistant_role_policy)
      allow(helper).to receive(:current_program).and_return(program)
    end

    it 'returns a message when the user is an assistant' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(true)

      expect(helper.disabled_standards_based_assigning_reason(nil)).to eq(
        'Standards-based Assigning is not available to Assistants'
      )
    end

    context 'when user is an instructor,' do
      before do
        allow(assistant_role_policy).to receive(:is_assistant?).and_return(false)
        allow(helper).to receive(:current_user).and_return(instructor)
      end


      context 'when course argument is not nil,' do
        it 'returns a message if specified course does not have any open sections' do
          course = create(:course)
          expect(helper.disabled_standards_based_assigning_reason(course)).to eq(
            "You currently don't have any open sections for this course"
          )
        end

        it 'returns nil if specified course has an open section' do
          create(:section_instructor, section: course_with_section.sections.first, instructor: instructor)
          expect(helper.disabled_standards_based_assigning_reason(course_with_section)).to be_nil
        end
      end

      context 'when course argument is nil' do
        it 'returns a message if course is nil' do
          expect(helper.disabled_standards_based_assigning_reason(nil)).to eq(
            "You currently don't have a course for this program"
          )
        end

        it 'returns a message if instructor has no ' \
           'open courses for the the current program' do
          expect(
            helper.disabled_standards_based_assigning_reason(nil)
          ).to eq("You currently don't have a course for this program")
        end

        it 'returns nil if the instructor has open courses' do
          create(:section_instructor, section: course_with_section.sections.first, instructor: instructor)
          expect(
            helper.disabled_standards_based_assigning_reason(nil)
          ).to be_nil
        end
      end
    end

    context 'when user is a co-instructor,' do
      before do
        allow(assistant_role_policy).to receive(:is_assistant?).and_return(false)
        allow(helper).to receive(:current_user).and_return(co_instructor)
      end


      context 'when course argument is not nil,' do
        it 'returns a message if specified course does not have any open sections' do
          course = create(:course)
          expect(helper.disabled_standards_based_assigning_reason(course)).to eq(
            "You currently don't have any open sections for this course"
          )
        end

        it 'returns nil if specified course has an open section' do
          create(:section_co_instructor, section: course_with_section.sections.first, instructor: co_instructor)
          expect(helper.disabled_standards_based_assigning_reason(course_with_section)).to be_nil
        end
      end

      context 'when course argument is nil' do
        it 'returns a message if course is nil' do
          expect(helper.disabled_standards_based_assigning_reason(nil)).to eq(
            "You currently don't have a course for this program"
          )
        end

        it 'returns a message if instructor has no ' \
           'open courses for the the current program' do
          expect(
            helper.disabled_standards_based_assigning_reason(nil)
          ).to eq("You currently don't have a course for this program")
        end

        it 'returns nil if the instructor has open courses' do
          create(:section_co_instructor, section: course_with_section.sections.first, instructor: co_instructor)
          expect(
            helper.disabled_standards_based_assigning_reason(nil)
          ).to be_nil
        end
      end
    end
  end

  describe '#hoverize' do
    context 'when the string and the hover are the same' do
      before(:each) do
        @results = hoverize('foo', 'foo')
      end

      it 'should return the string unmodified' do
        expect(@results).to eql 'foo'
      end

      it 'should be html_safe' do
        expect(@results).to be_html_safe
      end
    end

    context "when the string and the hover are different" do
      it "should return the string wrapped in a span, with the hover as the title" do
        expect(hoverize('foo', 'bar')).to eql '<span title="%s">%s</span>' % ['bar', 'foo']
      end

      it "should strip html_tags from the hover text" do
        expect(hoverize('foo', '<b>bar</b>')).to eql '<span title="%s">%s</span>' % ['bar', 'foo']
      end

      it "should be html_safe" do
        expect(hoverize('foo', 'bar')).to be_html_safe
        expect(hoverize('foo', '<b>bar</b>')).to be_html_safe
      end
    end
  end

  describe "#get_partial_locals" do
    it "raises an error if parameter is blank" do
      expect{ get_partial_locals nil }.to raise_error "partial locals missing"
    end

    context "when parameter has no :locals key" do
      it "returns an empty hash" do
        expect(get_partial_locals(:some_key => 'some_value')).to eql({})
      end
    end

    context "when parameter has a :locals key" do
      it "returns :locals value" do
        # returned locals hash will have symbol keys
        expected_result = {key: 'value'}
        expect(get_partial_locals('some_key' => 'some_value',
                                  'locals' => {'key' => 'value'})).to eql expected_result
      end
    end
  end

  describe "#get_partial_name" do
    it "raises an error if parameter is blank" do
      expect{ get_partial_name nil }.to raise_error "partial name missing"
    end

    it "raises an error if parameter has no :partial key" do
      expect{ get_partial_name(:some_key => 'some_value') }.to raise_error "partial name missing"
    end

    context "when parameter has a :partial" do
      it "returns :partial value" do
        expected_result = 'some_name'
        expect(get_partial_name(:some_key => 'some_value', 'partial' => 'some_name')).to eql expected_result
      end
    end
  end

  describe '#sanitize_with_data_remote' do
    let(:content) { '<a href="https://example.com" data-remote="true">Link</a>' }

    context 'when content has allowed tags and data-remote' do
      it 'sanitizes content and keeps the data-remote attribute' do
        result = helper.sanitize_with_data_remote(content)
        expect(result).to eq('<a href="https://example.com" data-remote="true">Link</a>')
      end
    end

    context 'when content has disallowed tags with data-remote' do
      let(:content_with_disallowed_tags) do
        '<script>alert("Hacked!");</script><a href="https://example.com" data-remote="true">Link</a>'
      end

      it 'removes disallowed tags and keeps the allowed ones' do
        result = helper.sanitize_with_data_remote(content)
        expect(result).to eq('<a href="https://example.com" data-remote="true">Link</a>')
      end
    end

    context 'when content has allowed tags without data-remote' do
      let(:content_without_data_remote) { '<a href="https://example.com">Link</a>' }

      it 'sanitizes the content and does not add data-remote if not present' do
        result = helper.sanitize_with_data_remote(content_without_data_remote)
        expect(result).to eq('<a href="https://example.com">Link</a>')
      end
    end

    context 'when content contains disallowed attributes' do
      let(:content_with_disallowed_attributes) do
        '<a href="https://example.com" onclick="alert(\'Hacked!\')">Link</a>'
      end

      it 'removes disallowed attributes' do
        result = helper.sanitize_with_data_remote(content_with_disallowed_attributes)
        expect(result).to eq('<a href="https://example.com">Link</a>')
      end
    end
  end

  describe "#html_string_shorten" do
     let(:str) { "This is a <i><b>long</b> string </i>" }

     it "returns a shortened string" do
       expect(html_string_shorten(str, 12)).to eql( ("This is a <i><b>lo</b></i>") + "&hellip;".html_decode)
     end

  end
  describe "#html_strip_and_decode" do
    it "strips html tags" do
      expect(html_strip_and_decode('Alpha <b>Bravo</b>')).to eql 'Alpha Bravo'
    end

    it "de-entitizes html entities" do
      expect(html_strip_and_decode('Le tabac pourrait bient&ocirc;t &#234;tre banni dans tous les lieux publics en France')).to eql 'Le tabac pourrait bientôt être banni dans tous les lieux publics en France'
      expect(html_strip_and_decode('Charlie D&eacute;lta')).to eql 'Charlie Délta'
    end
  end

  describe "#current_url_contains?" do
    it "should be true if the current uri starts with the passed uri" do
      path_param = '/path/to/action'
      allow(@controller.request).to receive(:request_uri).and_return(path_param + '/sub_action')
      allow(@controller).to receive(:url_for).and_return(path_param)
      expect(current_url_contains?(path_param)).to be_truthy
    end
    it "should be false it the current uri does not start with the passed uri" do
      path_param = '/path/to/action'
      allow(@controller.request).to receive(:request_uri).and_return('/path/to/another_action')
      allow(@controller).to receive(:url_for).and_return(path_param)
      expect(current_url_contains?(path_param)).to be_falsey
    end
  end

  describe "#format_sample_answer" do
    let(:sanitize_options) { { tags: %w[span strong em], attributes: %w[lang class] } }

    context "when sample_answer is a string" do
      it "sanitizes the string with allowed tags and attributes" do
        sample_answer = "<span class='test' lang='en'>Answer</span><script>alert('xss')</script>"
        expected = "<span class=\"test\" lang=\"en\">Answer</span>alert('xss')"
        expect(format_sample_answer(sample_answer)).to eq(expected)
      end

      it "allows strong tags in the answer" do
        sample_answer = "This is a <strong>bold</strong> answer"
        expect(format_sample_answer(sample_answer)).to eq(sample_answer)
      end

      it "allows em tags in the answer" do
        sample_answer = "This is an <em>emphasized</em> answer"
        expect(format_sample_answer(sample_answer)).to eq(sample_answer)
      end

      it "removes disallowed tags" do
        sample_answer = "Answer with <div>div</div> and <p>paragraph</p>"
        expect(format_sample_answer(sample_answer)).to eq("Answer with div and paragraph")
      end
    end

    context "when sample_answer is an array" do
      it "formats and joins array elements with quotes and commas" do
        sample_answer = ["First answer", "Second answer"]
        expected = "[\"First answer\", \"Second answer\"]"
        expect(format_sample_answer(sample_answer)).to eq(expected)
      end

      it "sanitizes each array element" do
        sample_answer = [
          "<span class='test'>First</span><script>alert('xss')</script>",
          "<em>Second</em><div>removed</div>"
        ]
        expected = "[\"<span class=\"test\">First</span>alert('xss')\", \"<em>Second</em>removed\"]"
        expect(format_sample_answer(sample_answer)).to eq(expected)
      end
    end
  end

  describe "#format_element_with_disabled_explanation" do
    it "should raise an error if passed a blank element id" do
      expect{ format_element_with_disabled_explanation('', disabled = true) }.to raise_error 'element_id cannot be blank'
    end

    it "should raise an error if passed a nil element id" do
      expect{ format_element_with_disabled_explanation(nil, disabled = true) }.to raise_error 'element_id cannot be blank'
    end

    context "when the element is disabled," do

      it "should yield element passed in as a block" do
        result = format_element_with_disabled_explanation('my_element', disabled = true){ '<span>abc</span>'.html_safe }
        expect(result).to have_selector(".disabled_element_wrapper span", :text => 'abc')
      end

      it "should return a wrapper div for the element that is disabled" do
        element_id = "my_element"
        result = format_element_with_disabled_explanation(element_id, disabled = true){ 'abc' }
        expect(result).to have_selector("div.disabled_element_wrapper[rel='##{element_id}_explanation'][id='#{element_id}']")
      end

      context "when passed a blank message," do
        it "should return a default disabled message" do
          element_id = "my_element"
          expected_message = "This item is currently disabled."

          result = format_element_with_disabled_explanation(element_id, disabled = true){ 'abc' }
          expect(result).to have_selector("div.disabled_element_wrapper div[id='#{element_id}_explanation'][style='display: none;']", text: expected_message)
        end
      end

      context "when passed a non-blank message," do
        it "should return a hidden div containing the message" do
          element_id = "my_element"
          expected_message = "You can't do that."

          result = format_element_with_disabled_explanation(element_id, disabled = true, expected_message){ 'abc' }
          expect(result).to have_selector(".disabled_element_wrapper div[style='display: none;'][id='#{element_id}_explanation']", text: expected_message)
        end
      end

      context "when add overlay div is enabled" do
        it "displays a div that is positioned absolutely to cover the element" do
          element_id = "my_element"
          expected_message = "You can't do that."
          result = format_element_with_disabled_explanation(element_id, disabled = true, 'message', add_overlay_div = true){ 'abc' }
          expect(result).to have_selector('div[style="position: absolute; left: 0; right: 0; top: 0; bottom: 0;"]')
        end
      end

      context "when add overlay div is disabled" do
        it "does not display a div that is positioned absolutely to cover the element" do
          element_id = "my_element"
          expected_message = "You can't do that."
          result = format_element_with_disabled_explanation(element_id, disabled = true, expected_message, add_overlay_div = false){ 'abc' }
          expect(result).not_to have_selector('div[style="position: absolute; left: 0; right: 0; top: 0; bottom: 0;"]' )
        end
      end
    end

    context "when the element is not disabled," do

      it "should yield element passed in as a block" do
        result = format_element_with_disabled_explanation('my_element', disabled = false){ '<span>abc</span>'.html_safe }
        expect(result).to have_selector(".enabled_element_wrapper span", :text => 'abc')
      end

      it "should return a wrapper div for the element not disabled" do
        element_id = "my_element"
        result = format_element_with_disabled_explanation(element_id, disabled = false){ 'abc' }
        expect(result).to have_selector("div.enabled_element_wrapper[rel='##{element_id}_explanation'][id='#{element_id}']")
      end

      it "should not return a disabled message" do
        element_id = "my_element"
        result = format_element_with_disabled_explanation(element_id, disabled = false){ 'abc' }
        expect(result).not_to have_selector("div[id='#{element_id}_explanation']")
      end
    end

  end

  describe "#format_last_login_date" do

    before(:each) do
      @user = build_stubbed(:student)
    end

    context "when a user has a current login date," do
      it "should return the current login date formatted in standard date format" do
        expected_date = 1.month.ago
        allow(@user).to receive(:current_login_at).and_return(expected_date)
        expect(format_last_login_date(@user)).to eql format_date_time(expected_date, :standard)
      end
    end

    context "when a user does not have a current login date," do
      before(:each) do
        allow(@user).to receive(:current_login_at).and_return(nil)
      end

      context "when the user has a last login date," do
        it "should return the last login date formatted in standard date format" do
          expected_date = 2.month.ago
          allow(@user).to receive(:last_login_at).and_return(expected_date)
          expect(format_last_login_date(@user)).to eql format_date_time(expected_date, :standard)
        end
      end

      context "when the user has no last login date," do
        it "should return 'Never'" do
          allow(@user).to receive(:last_login_at).and_return(nil)
          expect(format_last_login_date(@user)).to eql 'Never'
        end
      end
    end

  end

  describe "#format_error_class" do
    context "when there are no errors," do
      it "returns the default class when there are no errors" do
        errors = Hash.new
        object = double('ActiveRecordObject', :errors => errors)
        expect(format_error_class(object, :any_field, 'default_class')).to eql 'default_class'
      end

      it "returns the default class when there are no errors on the specified field" do
        errors = {:other_field => true}
        object = double('ActiveRecordObject', :errors => errors)
        expect(format_error_class(object, :any_field, 'default_class')).to eql 'default_class'
      end
    end

    context "when there are errors on the specified field," do
      before(:each) do
        @errors = {:error_field => true}
        @object = double('ActiveRecordObject', :errors => @errors)
      end

      it "adds errors class to default class if specified" do
        expect(format_error_class(@object, :error_field, 'default_class')).to eql 'fieldWithErrors default_class'
      end

      it "returns errors class to if no default class is specified" do
        expect(format_error_class(@object, :error_field)).to eql 'fieldWithErrors'
      end
    end
  end

  describe '#format_program_logo_link' do
    let(:program) { build_stubbed(:program) }
    let(:section) { build_stubbed(:section, course: build_stubbed(:course)) }
    let(:user) { build_stubbed(:student) }

    it 'returns the default link when passed a nil current user' do
      response = format_program_logo_link(program, nil, section)
      expect(response).to have_selector('a[href="/"] img[src*="vista_logo.png"]')
    end

    it 'returns the default link when passed a program with no logo media' do
      allow(program).to receive(:logo_media).and_return(nil)
      response = format_program_logo_link(program, user, section)
      expect(response).to have_selector('a[href="/"] img[src*="vista_logo.png"]')
    end

    it 'returns the default link when passed a nil program' do
      response = format_program_logo_link(nil, user, section)
      expect(response).to have_selector('a[href="/"] img[src*="vista_logo.png"]')
    end

    context 'when passed a program with logo media,' do
      let(:media) { build_stubbed(:media_item_image) }

      before do
        allow(program).to receive(:logo_media).and_return(media)
      end

      it 'returns the program logo image as a link' do
        allow(helper).to receive(:current?)
        response = helper.format_program_logo_link(program, user, section)
        expect(response).to have_selector("a img[src*='#{media.filename}']")
      end

      it 'sets the program image height to 35% if short param is true' do
        allow(helper).to receive(:current?)
        response = helper.format_program_logo_link(
          program, user, section, _short = true
        )
        expect(response).to have_selector('a > img[height="50%"]')
      end

      it 'links to the program dashboard if the user is an instructor' do
        allow(helper).to receive(:current?)
        allow(user).to receive(:instructor?).and_return(true)
        response = helper.format_program_logo_link(program, user, section)
        expect(response).to have_selector(
          "a[href='#{instructor_dashboard_path(program)}']"
        )
      end

      context 'when user is not an instructor,' do
        before do
          allow(user).to receive(:instructor?).and_return(false)
        end

        context 'with a Supersite Junior program,' do
          let(:program) { build_stubbed(:ss_jr_program) }

          it 'links to the Supersite Junior student dashboard if student is ' \
             'in a section' do
            allow(helper).to receive(:current?)
            response = helper.format_program_logo_link(program, user, section)
            expected_url = jr_course_section_path(
              course_id: section.course_id, section_id: section.id
            )
            expect(response).to have_selector("a[href='#{expected_url}']")
          end

          it 'links to the Supersite Junior contents page if student ' \
             'is not in a section' do
            allow(helper).to receive(:current?)
            response = helper.format_program_logo_link(program, user, _section = nil)
            expected_url = jr_section_program_content_path(
              section_id: 0, program_id: program.id
            )
            expect(response).to have_selector("a[href='#{expected_url}']")
          end
        end

        context 'with a non-Supersite Junior program,' do
          it 'links to the non-Supersite Junior student dashboard if student ' \
             'is in a section' do
            allow(helper).to receive(:current?)
            response = helper.format_program_logo_link(program, user, section)
            expect(response).to have_selector(
              "a[href='#{course_section_path(section.course, section)}']"
            )
          end

          it 'links to the program table of contents if student ' \
             'is not in a section' do
            allow(helper).to receive(:current?)
            response = helper.format_program_logo_link(program, user, _section = nil)
            expect(response).to have_selector(
              "a[href='#{section_toc_path('0', program)}']"
            )
          end
        end
      end
    end
  end

  describe "#display_linked_media_item" do

    include MediaItemsHelper
    context "open media" do
      it "should format for error display when invalid" do
        link = double(MediaLink, :open? => true, :media_item_id => 5)
        allow(link).to receive(:is_a?).with(MediaLink).and_return('MediaLink')
        result = display_linked_media_item(link)
        expect(result).to have_selector("span[class='media_item'] span[class='error']")
      end

      it "should raise an exception when given a nil media_item to display" do
        expect{display_linked_media_item(nil) }.to raise_error(/invalid MediaLink/)
      end

    end

    context "valid media" do
      let(:img_attributes) do
        {
          alt_tag: 'image alt tag',
          filename: 'image_file_name',
          height: 20,
          long_description: nil,
          media_type: 'image',
          width: 10
        }
      end

      it "returns an audio player for audio media_items" do
        media_item = double(MediaItem, media_type: 'audio',
                                       public_filename: 'audio_file_name',
                                       filename: 'audio_file_name',
                                       width: nil,
                                       height: nil,
                                       alt_tag: nil)
        link = double(MediaLink, :media_item => media_item, :open? => false)
        allow(link).to receive(:is_a?).with(MediaLink).and_return('MediaLink')
        allow(self).to receive(:render)

        display_linked_media_item(link)

        expect(self).to have_received(:render).with(
          'media_items/audio_player',
          media_item: media_item, auto_play: 0, reference: nil, reference_in_artifact: nil, submission_status: nil
        )
      end

      it "returns an img tag for image media_items" do
        media_item = create(:media_item, img_attributes)

        link = instance_double(MediaLink, :media_item => media_item, :open? => false)
        allow(link).to receive(:is_a?).with(MediaLink).and_return('MediaLink')
        result = display_linked_media_item(link)
        expect(result).to have_selector("img[src='#{media_item.public_filename}']")
      end

      it 'renders a partial for images when the media item has a long description' do
        media_item = create(:media_item,
                            img_attributes.merge(long_description: 'I am here, present')
                           )

        link = instance_double(MediaLink, media_item: media_item, open?: false)
        allow(link).to receive(:is_a?).with(MediaLink).and_return('MediaLink')

        result = display_linked_media_item(link)
        expect(result).to have_selector("#longdesc-for-#{media_item.id}")
      end

      it "returns a video player for video media_items" do
        media_item = double(MediaItem, media_type: 'video',
                                       public_filename: 'video_file_name',
                                       filename: 'video_file_name',
                                       width: nil,
                                       height: nil,
                                       alt_tag: nil)
        link = double(MediaLink, :media_item => media_item, :open? => false)
        allow(link).to receive(:is_a?).with(MediaLink).and_return('MediaLink')
        expect(self).to receive(:render).with(partial: 'media_items/video_player',
                                              locals: { media_item: media_item,
                                                        record_button_for_question: nil,
                                                        reference: nil })
        display_linked_media_item(link)
      end
    end
  end

  describe "#format_due_date" do
    it "returns dates in weekday, month, ordinal_day format preceeded by 'Due'" do
      @datetime = Date.parse('2009-09-10')
      formatted = format_due_date(@datetime)
      expect(formatted).to eql "Due Thursday, September 10th"
    end

    it "turns the date into a url if one is provided" do
      @datetime = Date.parse('2009-09-10')
      formatted = format_due_date(@datetime, 'valid_url')
      expect(formatted).to eql 'Due <a href="valid_url">Thursday, September 10th</a>'
    end
  end

  describe "#pluralize_without_count" do

    it "returns plural form if count is 0" do
      expect(pluralize_without_count(0, 'book')).to eql 'books'
    end

    it "returns singular form if count is 1" do
      expect(pluralize_without_count(1, 'book')).to eql 'book'
    end

    it "returns singular form if count is '1'" do
      expect(pluralize_without_count('1', 'book')).to eql 'book'
    end

    it "returns plural form if count is 2" do
      expect(pluralize_without_count(2, 'book')).to eql 'books'
    end
  end

  describe "#format_hours_minutes" do
    context "when not given a format" do
      it "should convert an integer into a string with hour and minute labels" do
        expect(format_hours_minutes(1)).to eql "1 minute"
        expect(format_hours_minutes(30)).to eql "30 minutes"
        expect(format_hours_minutes(60)).to eql "1 hour"
        expect(format_hours_minutes(125)).to eql "2 hours, 5 minutes"
      end
    end

    context "when given a format of ':short'" do
      it "should convert an integer into a string with short hour and minute labels" do
        expect(format_hours_minutes(1, :short)).to eql "1m"
        expect(format_hours_minutes(30, :short)).to eql "30m"
        expect(format_hours_minutes(60, :short)).to eql "1h"
        expect(format_hours_minutes(125, :short)).to eql "2h 5m"
      end
    end
  end

  describe "#when_unique" do
    before(:each) do
      @items = [{:id => 1, :type => 'one'}, {:id => 2, :type => 'one'},
                {:id => 3, :type => 'two'}, {:id => 4, :type => 'two'}, ]
    end

    context "when passed a block," do
      it "evaluates the block output" do
        output = Array.new
        @items.each do |item|
          when_unique(:type, item[:type]) do |type|
            output << "Type: #{type}"
          end
          output << item[:id]
        end
        expect(output).to eql ["Type: one", 1, 2, "Type: two", 3, 4]
      end

      it "should work properly with only one occurance of the value" do
        items = [{:id => 1, :type => :one}, {:id => 2, :type => :one},
                 {:id => 3, :type => :one}, {:id => 4, :type => :one}, ]
        output = Array.new
        items.each do |item|
          when_unique(:type, item[:type]) do |type|
            output << "Type: #{type}"
          end
          output << item[:id]
        end
        expect(output).to eql ["Type: one", 1, 2, 3, 4]
      end
    end

    context "when passed no block," do
      it "returns the unique value" do
        output = Array.new
        @items.each do |item|
          value = when_unique(:type, item[:type])
          output << value if value
          output << item[:id]
        end
        expect(output).to eql ["one", 1, 2, "two", 3, 4]
      end
    end

  end

  describe "#format_activity_icon" do
    before(:each) do
      @activity = build_stubbed(:activity)

      # stubbed music application helper - feature_icon.
      icon_path_titles = {
        'music/toc/audio' => 'Audio',
        'music/toc/textbook' => 'Textbook',
        'music/toc/vol_textbook' => 'Textbook',
        'music/toc/video' => 'Video',
        'music/toc/composition' => 'Composition',
        'music/toc/microphone' => 'Microphone',
        'music/toc/virtual_chat' => 'Virtual Chat',
        'music/toc/partner_chat' => 'Partner Chat',
        'music/toc/icon_person' => 'Instructor Graded',
        'music/toc/instructor_note_icon_rounded' => 'Instructor Note'}

      allow_any_instance_of(ApplicationHelper).to receive(:feature_icon) do |block, filepath|
        "<span class='c-embedded-icon'><svg><title>#{icon_path_titles[filepath]}</title></svg>".html_safe
      end
    end

    context "when the icon value is blank" do
      before do
        allow(@activity).to receive(:icon).and_return('')
        @result = format_activity_icon(@activity.icon)
      end

      it "should return a empty string" do
        expect(@result).to eql ''
      end

      it "should be html_safe" do
        expect(@result).to be_html_safe
      end
    end

    context "when the icon value is nil" do
      before do
        allow(@activity).to receive(:icon).and_return(nil)
        @result = format_activity_icon(@activity.icon)
      end

      it "should return a empty string" do
        expect(@result).to eql ''
      end

      it "should be html_safe" do
        expect(@result).to be_html_safe
      end
    end

    context "displays appropriate icons" do
      icons = {'audio,textbook' => 'Audio|Textbook',
               'textbook' => 'Textbook',
               'audio' => 'Audio',
               'video' => 'Video',
               'composition,textbook' => 'Composition|Textbook',
               'microphone' => 'Microphone',
               'microphone,textbook' => 'Microphone|Textbook',
               'virtual_chat' => 'Virtual Chat',
               'partner_chat' => 'Partner Chat'}

      icons.each_pair do |icon, icon_titles|
        it "validate icon #{icon}.svg and should be html_safe" do
          allow(@activity).to receive(:icon).and_return(icon)
          result_with_svg = format_activity_icon(@activity.icon, true)
          expect(result_with_svg).to be_html_safe
          icon_titles.split('|').each do |title|
            expect(result_with_svg).to have_selector('span.c-embedded-icon svg > title', text: title)
          end
        end

        it "validate icon #{icon}.png and should be html_safe" do
          allow(@activity).to receive(:icon).and_return(icon)
          result = format_activity_icon(@activity.icon)
          expect(result).to be_html_safe
          icon.split(',').each do |png|
            expect(result).to have_css("img[src*='#{png}.png']")
          end
        end
      end
    end
  end

  describe '#program_logo_link' do
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course) }
    let(:section) { build_stubbed(:section, course: course) }

    context 'with an instructor,' do
      let(:instructor) { build_stubbed(:instructor) }

      it 'returns the instructor dashboard path' do
        # expect(@controller.main_app).to receive(:instructor_dashboard_path).with(program)
        expect(
          program_logo_link(program, instructor, section)
        ).to eq(instructor_dashboard_path(program))
      end
    end

    context 'with a student,' do
      let(:student) { build_stubbed(:student) }
      let(:section_zero) { Section.section_zero }

      context 'with a Supersite Junior program,' do
        let(:program) { build_stubbed(:ss_jr_program) }

        it 'links to the Supersite Junior student dashboard if student is ' \
           'in a section' do
          expect(program_logo_link(program, student, section)).to eq(
            jr_course_section_path(
              course_id: section.course_id, section_id: section.id
            )
          )
        end

        it 'links to the Supersite Junior content page if student ' \
           'is not in a section' do
          expect(program_logo_link(program, student, section_zero)).to eq(
            jr_section_program_content_path(section_id: 0, program_id: program.id)
          )
        end
      end

      context 'with a non-Supersite Junior program,' do
        it 'links to the non-Supersite Junior student dashboard if student ' \
           'is in a section' do
          expect(
            program_logo_link(program, student, section)
          ).to eq(course_section_path(course, section))
        end

        it 'links to the program table of contents if student ' \
           'is not in a section' do
          expect(
            program_logo_link(program, student, section_zero)
          ).to eq(section_toc_path('0', program))
        end
      end
    end
  end

  describe "#is_partial?" do
    it "should detect if the string has partial" do
      expect(is_partial?(":error_partial")).to be_truthy
    end

    it "should detect if the string has partial" do
      expect(is_partial?(":warning_partial")).to be_truthy
    end
  end

  describe "#ua_host_url" do
    context "when a valid ua remote path is specified," do
      it "returns the url for that path with ua host" do
        expect(ua_host_url(:support_tools)).to eql "//#{ua_host}/support/"
      end

      it "returns the root url on ua" do
        expect(ua_host_url(:invalid_remote_path)).to eql "//#{ua_host}/"
      end

      it "returns the student instructions as url on ua" do
        user = build_stubbed(:student)
        expect(ua_host_url(:student_instructions, { :section_guid => '123' })).to eql "//#{ua_host}/section/123/student_instructions?instructor=1"
        expect(ua_host_url(:student_instructions, { :section_guid => '123' })).to eql "//#{ua_host}/section/123/student_instructions?instructor=1"
      end

      it "returns the login as url on ua" do
        section = create(:section)
        expect(ua_host_url(:login_as, section: section)).to eql "//#{ua_host}/instructor/login_as/#{section.guid}"
      end

      it "returns the login as with redirect url on ua" do
        section = create(:section)
        expect(ua_host_url(:login_as_with_redirect, section: section, return_to: '//www.test.com')).to eql "//#{ua_host}/instructor/login_as/#{section.guid}?course_id=#{section.course.id}&section_id=#{section.id}&return_to=//www.test.com"
      end

      it "returns the login back for :instructor_log_back_in" do
        expect(ua_host_url(:instructor_log_back_in)).to eql "//#{ua_host}/instructor/log_back_in"
      end

      it "returns the screencast ua path to the specified screencast id" do
        expect(ua_host_url(:screencast, {:screencast_topic_or_id => 1})).to eql "//#{ua_host}/screencasts/1"
      end

      it "returns the screencast topic ua path to the specified screencast topic" do
        expect(ua_host_url(:screencast_topic, {:screencast_topic_or_id => 'some_topic'})).to eql "//#{ua_host}/screencasts/topic/some_topic"
      end

      it "returns the ua path to an m2 program" do
        m2_program = build_stubbed(:m2_program)
        expect(ua_host_url(:m2_program, {:program_id => m2_program.id})).to eql "//#{ua_host}/m2_program/#{m2_program.id}"
      end

      it "returns the ua path to the trial introductory video" do
        program = build_stubbed(:program)
        expect(ua_host_url(:introductory_video, {:program_id => program.id})).to eql "//#{ua_host}/trial_introduction_video/#{program.id}"
      end

      it "returns the ua path for creating a new partner context link" do
        expect(ua_host_url(:new_partner_integration_partner_context_link, :context_id => 'foo')).to eql "//#{ua_host}/partner_integration/partner_context_link/new?context_id=foo"
      end
    end
  end

  describe "#format_screencast_context_link" do
    context "when given a topic string" do
      before do
        @response = format_screencast_context_link('topic_string', 'title text')
      end

      it "should have a screencast icon" do
        expect(@response).to have_selector '.test-screencast-icon'
      end

      it "should generate a link to that topic" do
        expect(@response).to have_selector "a[href='#{ua_host_url(:screencast_topic, { :screencast_topic_or_id => 'topic_string' })}']"
      end

      it "should have c-embedded-icon-screen icon" do
        expect(@response).to have_selector "a span.c-embedded-icon--screen"
      end

      it "should have a tooltip" do
        expect(@response).to have_selector "a[title='title text']"
      end
   end

    context "when given a screencast id" do
      before do
        @response = format_screencast_context_link(1, 'title text')
      end

      it "should have a screencast icon" do
        expect(@response).to have_selector '.test-screencast-icon'
      end

      it "should generate a link to that topic" do
        expect(@response).to have_selector "a[href='#{ua_host_url(:screencast, { :screencast_topic_or_id => 1 })}']"
      end

      it "should have c-embedded-icon-screen icon" do
        expect(@response).to have_selector "a span.c-embedded-icon--screen"
      end

      it "should use the title of the screencast as its tooltip" do
        expect(@response).to have_selector "a[title='title text']"
      end
    end

    context "when not given title text" do
      it "should not have a title attribute" do
        expect(format_screencast_context_link('topic_string')).not_to have_selector('img[title=""]')
      end
    end
  end

  describe "#short_month" do
    it "returns a short month" do
      expect(short_month(Date.new(2012,1,31))).to eq("Jan")
      expect(short_month(Date.new(2012,12,1))).to eq("Dec")
    end
  end

  describe '#screencasts_link' do

    context 'given a student' do
      it 'returns a link to the student screencasts on ua with a source of m3' do
        allow(helper).to receive(:current_user).and_return(build_stubbed(:student))
        expect(helper.screencasts_link).to match /screencasts\/student\?source=m3/
      end
    end

    context 'given an instructor' do
      it 'returns a link to the instructor screencasts on ua with a source of m3' do
        allow(helper).to receive(:current_user).and_return(build_stubbed(:instructor))
        expect(helper.screencasts_link).to match /screencasts\/instructor\?source=m3/
      end
    end

    context 'given a user who has not logged in yet' do
      it 'returns a link to student screencasts' do
        allow(helper).to receive(:current_user).and_return(nil)
        expect(helper.screencasts_link).to match /screencasts\/student\?source=m3/
      end
    end
  end

  describe '#display_demo_access_information' do
    let(:program) { build_stubbed(:program) }
    let(:access_guardian) { AccessGuardian.new(@user, @program) }

    before do
      allow(helper).to receive(:current_program).and_return(program)
    end

    it 'returns nothing if there is no current user' do
      allow(helper).to receive(:current_user).and_return(nil)
      expect(helper.display_demo_access_information).to be_nil
    end

   it 'returns nothing if user is not an instructor' do
      allow(helper).to receive(:current_user).and_return(build_stubbed(:student))
      expect(helper.display_demo_access_information).to be_nil
    end

    context 'when current user is an instructor' do
      let(:instructor) { build_stubbed(:instructor) }

      before do
        allow(helper).to receive(:access_guardian).and_return(access_guardian)
        allow(helper).to receive(:current_user).and_return(instructor)
      end

      it 'returns nothing if user does not currently have demo access to the current program' do
        expect(access_guardian).to receive(:has_unexpired_demo_access?).and_return(false)
        expect(helper.display_demo_access_information).to be_nil
      end

      context 'when instructor currently has demo access to the current program' do
        let(:formatter) { double('AccessOptionFormatter', :time_remaining_message => 'valid trial access message') }

        before do
          allow(access_guardian).to receive(:has_unexpired_demo_access?).and_return(true)
          allow(access_guardian).to receive(:ever_had_demo_access?).and_return(true)
          allow(access_guardian).to receive(:demo_access_expiration_date).and_return(Date.today)
          allow(instructor).to receive(:demo_course_current?).and_return(true)

          allow(Formatters::AccessOptions).to receive(:new).and_return(formatter)
        end

        it 'creates a formatter, specifying instructors demo access info for current program' do
          expect(access_guardian).to receive(:ever_had_demo_access?).and_return(true)
          expect(access_guardian).to receive(:demo_access_expiration_date).and_return(Date.today)
          expect(Formatters::AccessOptions).to receive(:new).with(true, Date.today).and_return(formatter)
          helper.display_demo_access_information
        end

        it 'displays the time remaining message of the formatter it creates' do
          expect(helper.display_demo_access_information).to include formatter.time_remaining_message
        end

        it "displays a link to the introductory video for supersite programs" do
          # test disabled until supersite videos are updated.
          # expect(helper.display_demo_access_information).to include('Replay Intro Video')
          # expect(helper.display_demo_access_information)
          #   .to include(ua_host_url(:introductory_video,
          #                           { :program_id => program.id }))
        end

        context 'and the program is a VOL program' do
          let(:program) { build_stubbed(:program, family: 'vista_online_learning') }

          it "does not display a link to the introductory video" do
            expect(helper.display_demo_access_information)
              .not_to include('Replay Intro Video')
            expect(helper.display_demo_access_information)
              .not_to include(ua_host_url(:introductory_video,
                                          { :program_id => program.id }))
          end
        end
      end
    end
  end

  describe '#program_has_activities' do
    let(:program_settings) { double(ProgramSettings)}
    it 'return false when program settings set activity hidden' do
      allow(program_settings).to receive(:has_activities?) { false }
      expect(program_has_activities?).to eq program_settings.has_activities?
    end
    it 'return true when program settings set show activity' do
      allow(program_settings).to receive(:has_activities?) { true }
      expect(program_has_activities?).to eq program_settings.has_activities?
    end
  end

  describe '#program_has_my_content' do
    let(:program_settings) { double(ProgramSettings)}
    it 'return false when program settings set my content hidden' do
      allow(program_settings).to receive(:has_my_content?) { false }
      expect(program_has_my_content?).to eq program_settings.has_my_content?
    end
    it 'return true when program settings set show my content' do
      allow(program_settings).to receive(:has_my_content?) { true }
      expect(program_has_my_content?).to eq program_settings.has_my_content?
    end
  end

  describe '#program_has_audio_transcripts' do
    let(:program_settings) { instance_double(ProgramSettings)}
    it 'return false when program settings set Audio Transcript hidden' do
      allow(program_settings).to receive(:has_audio_transcripts?) { false }
      expect(program_has_audio_transcripts?).to eq program_settings.has_audio_transcripts?
    end
    it 'return true when program settings set show Audio Transcript' do
      allow(program_settings).to receive(:has_audio_transcripts?) { true }
      expect(program_has_audio_transcripts?).to eq program_settings.has_audio_transcripts?
    end
  end

  describe '#show_standards_assigning_link?' do
    let(:current_program) { create(:program) }
    let(:assistant_role_policy) { instance_double(AssistantRolePolicy) }

    it 'returns true when program supports and instructor is not assistant' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(false)
      allow(current_program).to receive(:show_standards_assigning_link?).and_return(true)
      expect(current_program.show_standards_assigning_link?).to be true
    end

    it 'returns false when program does not support' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(true)
      allow(current_program).to receive(:show_standards_assigning_link?).and_return(false)
      expect(current_program.show_standards_assigning_link?).to be false
    end

    it 'returns false when instructor is an assistant' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(true)
      allow(current_program).to receive(:show_standards_assigning_link?).and_return(false)
      expect(current_program.show_standards_assigning_link?).to be false
    end
  end

  describe '#ebook_label' do
    it 'returns the ebook label for the content menu assigned in the program settings' do
      program_setting = double(ProgramSettings, ebook_label: 'New eBook content menu title')

      allow(helper).to receive(:current_program)
      allow(ProgramSettings).to receive(:new).and_return(program_setting)

      expect(helper.ebook_label).to eq program_setting.ebook_label
    end
  end

  describe '#gradebook_link' do
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course) }
    let(:user) { build_stubbed(:instructor) }
    let(:section) { build_stubbed(:section) }
    let(:focus) { instance_double(Focus) }

    before do
      allow(helper).to receive(:current_program).and_return(program)
      allow(helper).to receive(:current_focus).and_return(focus)
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when there is no course in the current focus' do
      it 'defaults to the no_course link' do
        allow(focus).to receive(:course).and_return nil
        allow(helper).to receive(:no_course_link)
        url_helpers = Rails.application.routes.url_helpers
        allow(url_helpers).to receive(:gradebook_path)

        helper.gradebook_link
        expect(helper).to have_received(:no_course_link)
      end
    end

    context 'when there is a course in the current focus' do
      let(:url_helpers) { Rails.application.routes.url_helpers }

      before do
        allow(focus).to receive(:course).and_return(course)
      end

      context 'when there is a section in the current focus' do
        it 'returns link to gradebook section view' do
          allow(focus).to receive(:section_id).and_return(section.id)

          expect(helper.gradebook_link).to eq(
            gradebook_engine.course_section_scores_path(
              program.id,
              course.id,
              section.id
            )
          )
        end
      end

      context 'when there is a course, but no section, in the current focus' do
        it 'returns link to gradebook course view' do
          allow(focus).to receive(:section_id).and_return(nil)

          expect(helper.gradebook_link).to eq(
            gradebook_engine.course_path(
              program.id,
              course.id
            )
          )
        end
      end

      context 'when a section_id is passed' do
        it 'returns link to gradebook section view' do
          expect(helper.gradebook_link(section.id)).to eq(
            gradebook_engine.course_section_scores_path(
              program.id,
              course.id,
              section.id
            )
          )
        end
      end
    end
  end

  describe '#gradebook_category_link' do
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course) }
    let(:section) { build_stubbed(:section, course: course) }
    let(:category) { build_stubbed(:category, course: course) }
    let(:focus) { instance_double(Focus) }

    before do
      allow(helper).to receive(:current_program).and_return program
      allow(helper).to receive(:current_focus).and_return focus
    end

    it 'returns the gradebook section/scores path, passing in the category_id' do
      allow(focus).to receive(:course).and_return course
      allow(focus).to receive(:section_id).and_return section.id
      # helper.gradebook_category_link(section.id, category)

      expect(helper.gradebook_category_link(section.id, category)).to eq(
        gradebook_engine.course_section_scores_path(
          program.id,
          course.id,
          section.id,
          category_id: category.id,
          level: 'lesson',
          summary_level: 'section',
          summary_level_id: section.id
        )
      )
      # expect(gradebook_url_helpers).to have_received(:course_section_scores_path)
        # .with(program.id, course.id, section.id, any_args, hash_including(category_id: category.id))
    end
  end

  describe '#roster_link' do
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course) }
    let(:focus) { instance_double(Focus) }

    before do
      allow(helper).to receive(:current_focus).and_return(focus)
      allow(helper).to receive(:current_program).and_return(program)
    end

    context 'when there is no course in focus' do
      it 'links to the no_course view' do
        url_helpers = Rails.application.routes.url_helpers
        allow(url_helpers).to receive(:gradebook_path)
        allow(helper).to receive(:no_course_link)
        allow(helper).to receive(:focused_course).and_return nil

        helper.roster_link
        expect(helper).to have_received(:no_course_link)
      end
    end

    context 'when there is a course in focus' do
      before do
        allow(focus).to receive(:course).and_return(course)
      end

      it 'links to the m3 roster page' do
        program = build_stubbed(:program)
        section = build_stubbed(:section)
        allow(helper).to receive(:current_program).and_return program
        allow(helper).to receive(:current_section).and_return section

        expect(helper.roster_link).to eq "/#{program.id}/sections/#{section.id}/roster"
      end

      context 'when a section_id is provided' do
        it 'links to the m3 roster page for that section' do
          program = build_stubbed(:program)
          section = build_stubbed(:section)
          allow(helper).to receive(:current_program).and_return program
          expect(helper).to_not receive(:current_section)

          expect(helper.roster_link(section.id)).to eq "/#{program.id}/sections/#{section.id}/roster"
        end
      end
    end
  end

  describe '#focused_course' do
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course) }
    let(:other_course) { build_stubbed(:course) }
    let(:focus) { double() }
    let(:user) { double() }

    before do
      allow(helper).to receive(:current_program).and_return program
      allow(helper).to receive(:current_focus).and_return focus
      allow(helper).to receive(:current_user).and_return user
    end

    context 'if there is a course in focus' do
      it 'returns that course' do
        allow(focus).to receive(:course).and_return course
        expect(helper.focused_course).to eq course
      end
    end

    context 'if there is no course in focus' do
      before do
        allow(focus).to receive(:course).and_return nil
      end

      context 'if the current user has access to courses in the current program' do
        it 'returns the first of those courses' do
          courses = [course, other_course]
          allow(user).to receive(:courses_for_program).and_return courses
          expect(helper.focused_course).to eq course
        end
      end

      context 'if the current user does not have access to courses in the current program' do
        it 'returns nil' do
          allow(user).to receive(:courses_for_program).and_return []
          expect(helper.focused_course).to be nil
        end
      end
    end
  end

  describe 'student course dashboard links' do
    let(:user) { build_stubbed(:student) }
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course, program: program) }
    let(:section) { build_stubbed(:section, course: course) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_program).and_return(program)
      allow(helper).to receive(:focused_course).and_return(course)
      allow(helper).to receive(:current_section).and_return(section)
    end

    describe 'student_grade_summary_link' do
      it 'returns the expected link' do
        expect(helper.student_grade_summary_link)
          .to eq @controller.gradebook_engine.section_user_summary_path(program.id, section.id, user.id)
      end
    end

    describe 'student_grade_details_link' do
      it 'returns the expected link' do
        expect(helper.student_grade_details_link)
          .to eq @controller.gradebook_engine.section_user_details_path(program.id, section.id, user.id)
      end
    end

    describe 'no_course_link' do
      let(:school) { create(:school) }
      let(:instructor) { create(:instructor, schools: [school]) }

      before do
        allow(helper).to receive(:current_user).and_return(instructor)
      end

      it 'returns the gradebook no-course path' do
        expect(helper.no_course_link)
          .to eq @controller.gradebook_engine.no_course_path(program.id)
      end
    end
  end
end
