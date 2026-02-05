class MyDevise::RegistrationsController < Devise::RegistrationsController
  # GET /resource/sign_up
  def new
    super do |resource|
      resource.suggested_role = registration_params['suggested_role']
    end
  end

  # POST /resource
  def create
    super do |resource|
      if resource.persisted?
      # custom logic after successful signup
      else
        # error logic
      end
    end
  end

  private

  def registration_params
    params.permit(:suggested_role)
  end

  def sign_up_params
    params.require(:user).permit(:suggested_role, :email, :name, :password,
                                 :password_confirmation).tap do |whitelisted|
      whitelisted[:suggested_role] = whitelisted[:suggested_role].to_i if whitelisted[:suggested_role].present?
    end
  end

  protected

  def after_sign_up_path_for(_resource)
    home_welcome_path
  end
end
