class CopyrightController < ApplicationController
  def index
    @copyright_permissions = CopyrightPermission.all
    @organizations = Organization.all
  end
end
