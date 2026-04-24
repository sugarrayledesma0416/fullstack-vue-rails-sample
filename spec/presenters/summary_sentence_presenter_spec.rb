describe SummarySentencePresenter do
  context 'when making a location filter presenter' do
    let(:lesson){ build_stubbed(:lesson) }
    let(:strand){ build_stubbed(:toc_entry, :location => '1') }

    context 'when no lesson is set' do
      it 'should display Activities from all lessons' do
        filter = build_stubbed(:assignment_filter)
        presenter = SummarySentencePresenter.new('location', :filter => filter)
        result = presenter.sentence
        expect(result).to eql 'Activities from all lessons'
      end
    end

    context 'when only the lesson filter is set and it is set to Lesson 1' do
      it 'should display Activities from Lesson 1' do
        filter = build_stubbed(:assignment_filter, :lesson => lesson)
        presenter = SummarySentencePresenter.new('location', :filter => filter)
        result = presenter.sentence
        expect(result).to match /Activities from <.+>Lesson 1/
      end
    end

    context 'when the lesson filter is set to Lesson 1 and the strand filter is set to fotonovela' do
      it 'should display Activities from Lesson 1 in Fotonovela' do
        filter = build_stubbed(:assignment_filter, :lesson => lesson, :toc_entry_location => 1)
        presenter = SummarySentencePresenter.new('location', :filter => filter, :strands => [strand])
        result = presenter.sentence
        expect(result).to match /Activities from <.+>Lesson 1<.+> in <.+>#{strand.title}/
      end
    end

    context 'when the lesson filter is set to Lesson 1 and the strand filter is set to fotonovela and the component filter is set to tutorials' do
      it 'should display Tutorial Activities from Lesson 1 in Fotonovela' do
        filter = build_stubbed(:assignment_filter, :lesson => lesson, :toc_entry_location => 1, :component => 'Tutorials')
        presenter = SummarySentencePresenter.new('location', :filter => filter, :strands => [strand])
        result = presenter.sentence
        expect(result).to match /<.+>Tutorial<.+> Activities from <.+>Lesson 1<.+> in <.+>#{strand.title}/
      end
    end

    context 'when the lesson filter is set to Lesson 1 and the strand filter is not set and the component filter is set to tutorials' do
      it 'should display Tutorial Activities from Lesson 1' do
        filter = build_stubbed(:assignment_filter, :lesson => lesson, :component => 'Tutorials')
        presenter = SummarySentencePresenter.new('location', :filter => filter, :strands => [strand])
        result = presenter.sentence
        expect(result).to match /<.+>Tutorial<.+> Activities from <.+>Lesson 1<.+>/
      end
    end
  end

  context 'when making a previously assigned filter presenter' do
    let(:course) { build_stubbed(:course, :name => 'Course 1') }
    let(:section) { build_stubbed(:section, :id => 1, :course => course, :name => 'Section 1') }
    let(:category){ build_stubbed(:category, :id => 2, :name => 'Homework') }

    context 'when no previous section is set' do
      it 'should display All Activities even if we haven\'t previously assigned them' do
        filter = build_stubbed(:assignment_filter)
        presenter = SummarySentencePresenter.new('previously assigned', :filter => filter)
        result = presenter.sentence
        expect(result).to eql 'All Activities even if we haven\'t previously assigned them'
      end
    end

    context 'when only the previous section filter is set and it is set to Section 1' do
      it 'should display Activities that were assigned for Section 1' do
        filter = build_stubbed(:assignment_filter, :previous_section_id => 1 )
        allow(filter).to receive(:previous_section).and_return(section)
        presenter = SummarySentencePresenter.new('previously assigned', :filter => filter )
        result = presenter.sentence
        expect(result).to match /Activities that were assigned for <.+>Course 1 Section 1/
      end
    end

    context 'when the previous section filter is set to Section 1 and the category filter is set to Homework' do
      it 'should display Activities that were assigned for Section 1 as Homework' do
        filter = build_stubbed(:assignment_filter, :previous_section_id => 1, :category_id => 2 )
        allow(filter).to receive(:previous_section).and_return(section)
        allow(filter).to receive(:category).and_return(category)
        presenter = SummarySentencePresenter.new('previously assigned', :filter => filter )
        result = presenter.sentence
        expect(result).to match /Activities that were assigned for <.+>Course 1 Section 1<.+> as <.+>Homework/
      end
    end

    context 'when the previous section filter is set to Section 1 and the category filter is set to Homework and the week filter is set to Week 1' do
      it 'should display Activities that were assigned for Section 1 in Week 1 as Homework' do
        filter = build_stubbed(:assignment_filter, :previous_section_id => 1, :category_id => 2, :week => Date.today.to_s )
        allow(filter).to receive(:previous_section).and_return(section)
        allow(filter).to receive(:category).and_return(category)
        presenter = SummarySentencePresenter.new('previously assigned', :filter => filter)
        allow(presenter).to receive(:week_number).and_return(1)
        result = presenter.sentence
        expect(result).to match /Activities that were assigned for <.+>Course 1 Section 1<.+> in <.+>Week 1<.+> as <.+>Homework/
      end
    end

    context 'when the previous section filter is set to Section 1 and the category filter is set to Homework and the day filter is set to 2011-11-8' do
      it 'should display Activities that were assigned for Section 1 on Tue Nov 8, 2011 as Homework' do
        filter = build_stubbed(:assignment_filter, :previous_section_id => 1, :category_id => 2, :day => Date.today.to_s )
        allow(filter).to receive(:previous_section).and_return(section)
        allow(filter).to receive(:category).and_return(category)
        presenter = SummarySentencePresenter.new('previously assigned', :filter => filter )
        result = presenter.sentence
        expect(result).to match /Activities that were assigned for <.+>Course 1 Section 1<.+> on <.+>#{Date.today.strftime('%a %b %e, %Y')}<.+> as <.+>Homework/
      end
    end


  end

  context 'when making a properties filter presenter' do
    context 'when no properties filter is set' do
      it 'should display All Activities ' do
        filter = build_stubbed(:assignment_filter)
        presenter = SummarySentencePresenter.new('properties', :filter => filter)
        result = presenter.sentence
        expect(result).to eql 'All Activities'
      end
    end

    context 'when only the type filter is set and it is set to Tutorial vocab' do
      it 'should display Tutorial vocab Activities' do
        filter = build_stubbed(:assignment_filter, :activity_type => 'tutorial_vocab')
        presenter = SummarySentencePresenter.new('properties', :filter => filter)
        result = presenter.sentence
        expect(result).to match '<.+>Tutorial vocabulary<.+> Activities'
      end
    end

    context 'when only the grading method filter is set and it is set to Instructor' do
      it 'should display Activities that are Instructor Graded' do
        filter = build_stubbed(:assignment_filter, :grading_method => 'instructor')
        presenter = SummarySentencePresenter.new('properties', :filter => filter)
        result = presenter.sentence
        expect(result).to match 'Activities that are <.+>Instructor<.+> Graded'
      end
    end

    context 'when the grading method filter is set and it is set to Instructor and the type filter is set and it is set to Tutorial vocab' do
      it 'should display Tutorial vocab Activities that are Instructor Graded' do
        filter = build_stubbed(:assignment_filter, :grading_method => 'instructor', :activity_type => 'tutorial_vocab')
        presenter = SummarySentencePresenter.new('properties', :filter => filter)
        result = presenter.sentence
        expect(result).to match '<.+>Tutorial vocabulary<.+> activities that are <.+>Instructor<.+> Graded'
      end
    end
  end
end
