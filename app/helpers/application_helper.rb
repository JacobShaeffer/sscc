module ApplicationHelper
  include Pagy::Frontend

  def log(string)
    puts "\e[38;2;0;255;0m#{string}\e[0m"
  end

  def warn(string)
    puts "\e[38;2;255;255;0m#{string}\e[0m"
  end

  def err(string)
    puts "\e[38;2;255;0;0m#{string}\e[0m"
  end

  def current_controller?(names)
    names.include?(params[:controller])
  end

  def render_turbo_stream_notice_messages
    turbo_stream.prepend 'notice', partial: 'layouts/notice'
  end

  def render_turbo_stream_alert_messages
    turbo_stream.prepend 'alert', partial: 'layouts/alert'
  end

  def inline_error_for(field, form_obj)
    html = []
    if form_obj.errors && form_obj.errors[field].any?
      html << form_obj.errors[field].map do |msg|
        tag.div msg, class: 'text-danger text-sm m-0 p-0'
      end
    end
    html.join.html_safe
  end

  def sort_indicator(filters:)
    direction = session.dig(filters, 'direction')
    return unless direction.present?

    render partial: 'shared/sort_indicator', locals: { direction: direction }
  end
end
