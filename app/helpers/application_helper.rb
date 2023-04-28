module ApplicationHelper
    def current_controller?(names)
        names.include?(params[:controller])
    end
end
