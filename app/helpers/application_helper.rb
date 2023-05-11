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
end
