class CopyrightController < ApplicationController
	before_action :authenticate_user!
  def index
    @copyright_permissions = CopyrightPermission.all
    @organizations = Organization.all
  end
end
