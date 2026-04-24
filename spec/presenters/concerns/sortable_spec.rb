require 'rails_helper'

RSpec.describe Sortable do
  subject(:presenter) { klass.new(req_params) }

  let(:req_params) { {} }
  let(:klass) do
    Class.new do
      include Sortable

      def initialize(req_params = {})
        @req_params = req_params
      end

      def base_url(options = {})
        Rails.application.routes.url_helpers.fake_path(options)
      end

      private def sort_columns
        @sort_columns ||= {
          name: 'users.name',
          created_at: 'users.created_at'
        }.freeze
      end

      private def sort_link_options(column)
        sort_link_params(column)
      end

      private def default_sort_column
        'users.created_at'
      end

      public :sort_column, :sort_direction
    end
  end

  before do
    allow(Rails).to receive_message_chain(:application, :routes, :url_helpers, :fake_path)
  end

  describe '#sort_link_direction' do
    let(:req_params) { { sort_column:, sort_direction: } }
    let(:column) { :name }

    context 'when invalid sort_column' do
      let(:sort_column) { 'invalid' }
      let(:sort_direction) { 'asc' }

      it 'returns unsorted' do
        expect(presenter.sort_link_direction(column)).to eq('unsorted')
      end
    end

    context 'when valid sort_column' do
      let(:sort_column) { column.to_s }

      context 'when invalid sort_direction' do
        let(:sort_direction) { 'invalid' }

        it 'returns default direction' do
          expect(presenter.sort_link_direction(column)).to eq('ascending')
        end
      end

      context 'when valid sort_direction' do
        let(:sort_direction) { 'desc' }

        it 'returns requested direction' do
          expect(presenter.sort_link_direction(column)).to eq('descending')
        end
      end
    end
  end

  describe '#sort_link' do
    context 'when invalid column to sort' do
      it 'generates the link with empty options' do
        presenter.sort_link(:invalid)

        expect(Rails.application.routes.url_helpers)
          .to have_received(:fake_path).with({})
      end
    end

    context 'when valid column to sort' do
      let(:req_params) { { sort_column:, sort_direction: } }

      context 'when sorting by another column' do
        let(:sort_column) { 'created_at' }
        let(:sort_direction) { 'desc' }

        it 'generates the link with the correct options' do
          presenter.sort_link(:name)

          expected_options = {
            sort_column: :name,
            sort_direction: :asc
          }

          expect(Rails.application.routes.url_helpers)
            .to have_received(:fake_path).with(expected_options)
        end
      end

      context 'when sorting by the same column' do
        let(:sort_column) { 'name' }

        context 'when sorting descending' do
          let(:sort_direction) { 'desc' }

          it 'generates the link with the correct options' do
            presenter.sort_link(:name)

            expected_options = {
              sort_column: :name,
              sort_direction: :asc
            }

            expect(Rails.application.routes.url_helpers)
              .to have_received(:fake_path).with(expected_options)
          end
        end

        context 'when sorting ascending' do
          let(:sort_direction) { 'asc' }

          it 'generates the link with the correct options' do
            presenter.sort_link(:name)

            expected_options = {
              sort_column: :name,
              sort_direction: :desc
            }

            expect(Rails.application.routes.url_helpers)
              .to have_received(:fake_path).with(expected_options)
          end
        end
      end
    end
  end

  describe '#sort_column' do
    let(:req_params) { { sort_column: } }

    context 'when invalid sort_column' do
      let(:sort_column) { 'invalid' }

      it 'returns the default sort column' do
        expect(presenter.sort_column).to eq('users.created_at')
      end
    end

    context 'when valid sort_column' do
      let(:sort_column) { 'name' }

      it 'returns the expected sort column' do
        expect(presenter.sort_column).to eq('users.name')
      end
    end
  end

  describe '#sort_direction' do
    let(:req_params) { { sort_direction: } }

    context 'when invalid sort_direction' do
      let(:sort_direction) { 'invalid' }

      it 'returns the default sort_direction' do
        expect(presenter.sort_direction).to eq(:asc)
      end
    end

    context 'when valid sort_direction' do
      let(:sort_direction) { 'desc' }

      it 'returns the expected sort directon' do
        expect(presenter.sort_direction).to eq(:desc)
      end
    end
  end
end
