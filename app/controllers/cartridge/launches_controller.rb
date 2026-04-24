module Cartridge
  class LaunchesController < ApplicationController
    include CartridgeViewable
    before_action :require_user
    before_action :validate_resource_link, only: %i[show]
    before_action :validate_lti_version, only: %i[show]
    layout 'music_v1/minimal'

    LEGACY_LTI_VERSION = '1.1.0'.freeze
    LATEST_LTI_VERSION = '1.3.0'.freeze
    SUPPORTED_LTI_VERSIONS = [LEGACY_LTI_VERSION, LATEST_LTI_VERSION].freeze

    def show
      course_section_creator = Cartridge::CourseSectionCreator.new(
        decoded_params,
        current_user,
        resource_link
      )
      course_section_creator.process

      if course_section_creator.success
        save_lti_params_to_session(course_section_creator)
        redirect_to resource_link.url(current_user, course_section_creator.section)
      elsif course_section_creator.errors[:closed_course].present?
        @message = course_section_creator.errors[:closed_course]
        render :closed_course
      else
        redirect_or_render_error_page(
          'Something wrong happened',
          course_section_creator.errors
        )
      end
    end

    def closed_course
      @message = course_section_creator.errors[:closed_course]
      render layout: 'music_v1/default'
    end

    private def validate_resource_link
      return if resource_link

      redirect_or_render_error_page(
        'Resource link does not exist',
        resource_link: 'Resource link does not exist'
      )
    end

    private def resource_link
      @resource_link ||= Cartridge::ResourceLink.find_by(resource_link_id: params[:resource_link_id])
    end

    private def validate_lti_version
      return if SUPPORTED_LTI_VERSIONS.include?(lti_version)

      redirect_or_render_error_page(
        'LTI version missing or not supported',
        lti_version: 'LTI version missing or not supported'
      )
    end

    private def lti_version
      @lti_version ||= decoded_params[:lti_version]
    end

    private def legacy_lti_version?
      lti_version == LEGACY_LTI_VERSION
    end

    private def redirect_or_render_error_page(message, errors)
      if decoded_params[:launch_presentation_return_url]
        redirect_to(
          generate_external_url(
            decoded_params[:launch_presentation_return_url],
            lti_errormsg: message
          )
        )
      else
        @errors = errors
        render 'cartridge/shared/error', status: :bad_request
      end
    end

    private def generate_external_url(url, params = {})
      URI(url).tap do |uri|
        uri.query = params.to_query
      end.to_s
    end

    private def save_lti_params_to_session(course_section_creator)
      section = course_section_creator.section
      session[:cartridge] = {
        current_section_id: section.id,
        lti_version: lti_version
      }.tap do |memo|
        if legacy_lti_version?
          memo[:consumer_guid] = decoded_params[:consumer_guid] 
        else
          memo[:platform_guid] = decoded_params[:platform_guid]
        end
      end
      session[:focus] = {
        section.course.program_id.to_s => {
          section_id: section.id,
          course_id: section.course.id
        }
      }
    end

    private def safe_params
      params.permit(:resource_link_id, :launch_params)
    end

    private def decoded_params
      @decoded_params ||= JWTPayload.decode(safe_params[:launch_params]).symbolize_keys
    end
  end
end
