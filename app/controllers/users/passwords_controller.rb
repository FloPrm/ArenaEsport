class Users::PasswordsController < Devise::PasswordsController

  protected
=begin
  def after_sending_reset_password_instructions_path_for(resource_name)
    #return your path
  end
=end
end
