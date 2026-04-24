describe Instructor::DashboardController do
  it_should_require_a_logged_in_user do
    user = build_stubbed(:instructor)
    program = build_stubbed(:program)
    allow(Program).to receive(:find).and_return(program)
    get :index, params: { program_id: program.id }
  end

  describe "GET 'index'" do
    let(:focus) { double(Focus).as_null_object }

    before do
      @program = build_stubbed(:program)

      allow(Program).to receive(:find).and_return(@program)
      allow(controller).to receive(:current_program).and_return(@program)
      @user = build_stubbed(:instructor)
      allow(@user).to receive(:has_current_access_to?).and_return(true)
      fake_login(@user)
      allow(controller).to receive(:current_user).and_return(@user)

      allow(Focus).to receive(:new).and_return(focus)

      @presenter = InstructorDashboardPresenter.new(@user, focus, program_id: @program)
      allow(InstructorDashboardPresenter).to receive(:new).and_return(@presenter)

      @menu_location = 'dashboard'
    end

    def do_request
      get 'index', params: { program_id: @program.id }
    end

    it_should_behave_like 'an action that assigns contextual help'
    it_should_behave_like 'an action that assigns menu location'

    it 'assigns the program' do
      do_request
      expect(assigns(:program)).to eq(@program)
    end

    it 'should be successful' do
      get 'index', params: { program_id: @program.id }
      expect(response).to be_successful
      expect(response).to render_template(:index)
      expect(assigns(:presenter)).to eq(@presenter)
    end

    it 'assigns the return_to' do
      get 'index', params: { program_id: @program.id }
      expect(assigns(:return_to)).to eq(request.fullpath)
    end

    describe 'the page title' do
      context 'when focused on a current course or section' do
        before do
          allow(@presenter).to receive(:focused_course_closed?).and_return(false)
          do_request
        end

        it 'says "Courses"' do
          expect(assigns(:page_title)).to eq('Courses')
        end
      end

      context 'when focused on a closed course or section' do
        before do
          allow(@presenter).to receive(:focused_course_closed?).and_return(true)
          do_request
        end

        it 'says "Old Course"' do
          expect(assigns(:page_title)).to eq('Old Course')
        end
      end
    end
  end

  describe '#section_and_category_averages' do
    let(:categories) do
      [build_stubbed(:category),
       build_stubbed(:category),
       build_stubbed(:category),
       build_stubbed(:category)]
    end
    let(:gb_api_results) do
      {:section=>0.074,
        :categories=>{categories[0].id.to_s => 0.06666666666666667,
                      categories[1].id.to_s => 0.009000000000000001,
                      categories[2].id.to_s => 0.0,
                      categories[3].id.to_s => 0.19}
      }
    end
    let(:section) { double(GradebookEngine::Section, id: 123) }

    def do_request(section_id)
      get(
        :section_and_category_averages,
        params: { program_id: 100, section_id: section_id }
      )
    end

    before do
      user = build_stubbed(:instructor)
      allow(user).to receive(:has_current_access_to?).and_return(true)
      fake_login(user)
      allow(controller).to receive(:current_user).and_return(user)
      allow(GradebookEngine::Section)
        .to receive(:find)
        .and_return(section)
      allow(section)
        .to receive(:categories)
        .and_return(categories)
    end

    it 'returns JSON with formatted scores' do
      allow(GradebookEngine::GradebookAPI)
        .to receive(:section_and_category_averages)
        .and_return(gb_api_results)
      expected_values =
        {'section_id' => section.id,
         'results' => {'average' => '7.4%',
                       'category_averages' => {categories[0].id.to_s => '6.7%',
                                               categories[1].id.to_s => '0.9%',
                                               categories[2].id.to_s => '0.0%',
                                               categories[3].id.to_s => '19.0%'
                                              }
                      }
        }
      response = do_request(section.id)
      expect(JSON.parse(response.body)).to eq expected_values
    end

    it 'returns a 0 when the category has no scores' do
      gb_api_results[:categories].delete(categories[3].id.to_s)

      allow(GradebookEngine::GradebookAPI)
        .to receive(:section_and_category_averages)
        .and_return(gb_api_results)

      expected_values =
        {'section_id' => section.id,
         'results' => {'average' => '7.4%',
                       'category_averages' => {categories[0].id.to_s => '6.7%',
                                               categories[1].id.to_s => '0.9%',
                                               categories[2].id.to_s => '0.0%',
                                               categories[3].id.to_s => '0.0%'
                                              }
                      }
        }
      response = do_request(section.id)
      expect(JSON.parse(response.body)).to eq expected_values
    end
  end

  describe '#reset_focus_from_template' do
    let(:focus) { double(Focus, 'template?' => true).as_null_object }

    before do
      allow(controller).to receive(:current_focus).and_return(focus)
      user = build_stubbed(:instructor)
      course = build(:course)
      allow(user).to receive(:courses_and_sections_for_focus).and_return({ course.id => nil})
      program = build_stubbed(:program)
      allow(controller).to receive(:current_program).and_return(program)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'resets focus from the template course' do
      controller.send('reset_focus_from_template')
      expect(assigns('current_focus')).not_to be_template
    end
  end
end
