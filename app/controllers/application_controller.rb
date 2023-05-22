class ApplicationController < ActionController::Base
	include Pundit::Authorization
	around_action :switch_locale

	rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

	def switch_locale(&action)
		locale = params[:locale] || I18n.default_locale
		I18n.with_locale(locale, &action)
	end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

end
