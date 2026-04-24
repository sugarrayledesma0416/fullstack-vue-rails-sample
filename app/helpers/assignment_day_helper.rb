
module AssignmentDayHelper

  def style_for_bank(bank)
    bank_style = nil
    bank_style = "border-left: 0.25rem solid #{bank.background_color};" unless bank.background_color.blank?
  end
 
end
