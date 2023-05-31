module ApplicationHelper
	def current_controller?(names)
		names.include?(params[:controller])
	end

	def render_turbo_stream_notice_messages
		turbo_stream.prepend "notice", partial: "layouts/notice"
	end

	def render_turbo_stream_alert_messages
		turbo_stream.prepend "alert", partial: "layouts/alert"
	end

	def inline_error_for(field, form_obj)
		html = []
		if form_obj.errors && form_obj.errors[field].any?
			html << form_obj.errors[field].map do |msg|
				tag.div msg, class: "text-danger text-sm m-0 p-0"
			end
		end
		html.join.html_safe
	end
end
