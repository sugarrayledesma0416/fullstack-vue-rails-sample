require 'rails_helper'
describe WorksetPresenter do

  # Define workset
  let(:workset) { create(:workset) }
  let(:concept_learn) { create(:concept, name: 'Learn') }
  let(:track_group_1) { create(:track_group, name: 'Learn') }
  let(:activity_learn) { create(:activity, concept: concept_learn) }
  let(:assignment_1) { double("assignment", track_group: track_group_1) }
  
  # Define attempt
  let(:attempt) { build_stubbed(:attempt) } 

  # Define activity
  let(:activity) { build_stubbed(:activity) }

  # Define group workset activities
  let(:group) { workset.grouped_activities(false).first }
  
  before(:each) do
    # adding workset items
    pair_1 = [activity_learn, assignment_1]
    allow(workset).to receive(:activities_and_assignments).and_return([pair_1])
    allow(workset).to receive(:assignments).and_return([assignment_1])
    allow(workset).to receive(:attempt).and_return(attempt)
    
    # set activity language
    allow(activity).to receive(:language).and_return('es')
  end
  
  describe 'group_name_color' do
    it 'applies #666 colour when online vista higher learning is defined' do
      presenter = described_class.new(activity, workset, true)
      presenter.group_name_color
      expect(presenter.lang_attr).to eq('en')
      expect(presenter.strand_style).to eq('--group-color: #666;')
    end

    it 'applies an especific colour when online vista higher learning is not defined' do
      presenter = described_class.new(activity, workset, false)
      presenter.group = group
      presenter.group_name_color
      expect(presenter.lang_attr).to eq('es')
      expect(presenter.strand_style).to eq('--group-color: #aabbcc')
    end
  end

  describe 'group_name' do
    let!(:presenter) { described_class.new(activity, workset, true) }
    before(:each) do
      presenter.group = group
    end
    it 'return a specific name when group has name' do
      expect(presenter.group_name).to eq('Learn')
    end

    it 'return activities as name when group does not have name' do
      group[:name] = nil
      expect(presenter.group_name).to eq('activities')
    end
  end
  
  describe 'assignment_list_styles: Applies styles and labels' do
    before(:each) do
      presenter.group = group
    end

    context 'when vista_online_learning is valid applies In Progress label and is-current class' do
      let!(:presenter) { described_class.new(activity, workset, true) }
    
      it 'applies white strand style when the workset activity is not the current and attemps is false' do
        allow(workset).to receive(:attempt).and_return(false)
        
        group[:assignments].each.with_index do |(workset_activity), index| 
          
          presenter.assignment_list_styles(workset_activity)
          expect(presenter.class_attr).not_to include('is-current')
          expect(presenter.status_label).not_to eq('In Progress')
          expect(presenter.strand_style).to eq('--activity-color: white;')
        end
      end

      it 'applies img checkmark and background for strand style when the workset activity is the 
      current and expanded_status is completed' do
        allow(attempt).to receive(:expanded_status).and_return('completed')
        group[:assignments].each.with_index do |(workset_activity), index|
          # Make workset_activity as current_activity
          allow(activity).to receive(:id).and_return(workset_activity.id)

          presenter.assignment_list_styles(workset_activity)
          expect(presenter.checkmark_role).to eq('img')
          expect(presenter.class_attr).to include('is-current')
          expect(presenter.status_label).to eq('In Progress')
          expect(presenter.strand_style).to eq('background-color: #eee; opacity: 1')
        end
      end
    end
    
    context 'when vista_online_learning is not valid and the workset activity is not current and 
      does not have attempts' do
      let!(:presenter) { described_class.new(activity, workset, false) }
      
      it 'applies presentation checkmark, openened label and specific color strand style' do
        group[:assignments].each.with_index do |(workset_activity), index| 
          presenter.assignment_list_styles(workset_activity)
          expect(presenter.checkmark_role).to eq('presentation')
          expect(presenter.class_attr).not_to include('is-current')
          expect(presenter.status_label).to eq('opened')
          expect(presenter.strand_style).to eq('--activity-color: #aabbcc')
        end
      end
    end
  end

end
