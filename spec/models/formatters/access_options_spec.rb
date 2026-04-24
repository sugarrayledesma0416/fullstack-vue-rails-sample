describe Formatters::AccessOptions do
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  it "raises an error when user has demo access but no expiration date is specified" do
    expect{ Formatters::AccessOptions.new(true, nil) }.to raise_error "Expiration date for demo access expected"
  end

  it "raises an error when specified expiration date is not a date" do
    expect{ Formatters::AccessOptions.new(true, 2) }.to raise_error "Expiration date for demo access invalid"
  end

  describe "#time_remaining_message" do
    it "returns an empty string when user has no expiration date" do
      formatter = Formatters::AccessOptions.new(false, nil)
      expect(formatter.time_remaining_message).to eql ''
    end

    context "when user has expiration date" do
      it "includes the proper message prefix when user has had demo access" do
        formatter = Formatters::AccessOptions.new(true, 30.days.from_now.to_date)
        expect(formatter.time_remaining_message).to include 'Trial Access'
      end

      it "includes the proper message prefix when user has not had demo access" do
        formatter = Formatters::AccessOptions.new(false, 30.days.from_now.to_date)
        expect(formatter.time_remaining_message).to include 'Access'
      end

      it "returns an empty string when expiration date is greater than 90 days" do
        formatter = Formatters::AccessOptions.new(true, 91.days.from_now.to_date)
        expect(formatter.time_remaining_message).to eql ''
      end

      it "returns a proper message sufix when expiration date is greater than 30 days" do
        expiration_date = 45.days.from_now.to_date
        formatter = Formatters::AccessOptions.new(true, expiration_date)
        expect(formatter.time_remaining_message).to include "expires on <span>#{format_date_time(expiration_date, :gradebook_cell_short)}</span>"
      end

      context "when expiration date is less or equal to 30 days" do
        it "returns a proper message sufix when remaining days are greater than 1" do
          expiration_date = 20.days.from_now.to_date
          formatter = Formatters::AccessOptions.new(true, expiration_date)
          expect(formatter.time_remaining_message).to include "expires in <span>20 days</span>"
        end

        it "returns a proper message sufix when there is only one remaining day" do
          expiration_date = 1.day.from_now.to_date
          formatter = Formatters::AccessOptions.new(true, expiration_date)
          expect(formatter.time_remaining_message).to include "expires <span>tomorrow</span>"
        end
      end

      it "returns a proper message sufix when expiration date is today" do
        expiration_date = Time.now.to_date
        formatter = Formatters::AccessOptions.new(true, expiration_date)
        expect(formatter.time_remaining_message).to include "expires <span>today</span>"
      end

      it "returns a proper message sufix when access has expired" do
        expiration_date = 41.day.ago.to_date
        formatter = Formatters::AccessOptions.new(true, expiration_date)
        expect(formatter.time_remaining_message).to include "has expired"
      end
    end
  end

end
