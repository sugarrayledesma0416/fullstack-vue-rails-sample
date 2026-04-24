class ClientTokenController < ApplicationController
  def new
    user_guid = User.find_guid(params[:id])

    # Section 0 needs to handled nicely.
    if params[:section_id].to_i == 0
      course_guid = 0
    else
      section = Section.find(params[:section_id])
      course_guid = section.course.guid
    end

    token = Maestro::ApiToken.fetch(user_guid, course_guid)

    if token.secret
      respond_to do |format|
        format.json { render :json => { password: token.secret,
                                        jid: token.jid } }
      end
    else
      head :forbidden
    end
  end
end
