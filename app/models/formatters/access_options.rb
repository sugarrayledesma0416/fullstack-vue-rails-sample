module Formatters
  class AccessOptions
    include ApplicationHelper
    include ActionView::Helpers::TagHelper
    include Rails.application.routes.url_helpers
    
    def initialize(ever_had_demo_access, expiration_date = nil)
      raise "Expiration date for demo access expected" if ever_had_demo_access && expiration_date == nil
      raise "Expiration date for demo access invalid" if ever_had_demo_access && !expiration_date.is_a?(Date)
      @ever_had_demo_access = ever_had_demo_access
      @expiration_date = expiration_date
    end
    
    def time_remaining_message
      message = ''
      if @expiration_date.present?
        expiration_days = (@expiration_date - Date.today).to_i 
        message_prefix = @ever_had_demo_access ? 'Trial Access' : 'Access'
        message_sufix = expiration_text(expiration_days)
        
        if expiration_days <= 90
          message = content_tag(:div, "#{message_prefix} #{message_sufix}".html_safe, 'data-content-type' => 'time_remaining_info')      
        end
      end
      message
    end
    
    def expiration_text(days_remaining)
      case
      when days_remaining > 30 then "expires on <span>#{format_date_time(@expiration_date, :gradebook_cell_short)}</span>"
      when days_remaining > 1 then "expires in <span>#{days_remaining} days</span>"
      when days_remaining == 1 then "expires <span>tomorrow</span>"
      when days_remaining == 0 then "expires <span>today</span>"
      else "has expired"
      end
    end
    private :expiration_text
    
       
  end
end  
