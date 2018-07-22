class Users::RegistrationsController < Devise::RegistrationsController

  def create
    if params[:token].present?
      puts "\n\n #{params[:token]} \n\n"
      build_resource(sign_up_params)
      @token = params[:token] unless params[:token].nil? or params[:token].empty?
      unless @token.nil?
        @invitation = Invitation.find_by_token(@token)
        resource.parrain = @invitation.sender_id
        resource.save
        unless @user.nil?
          Friendship.create(user_id: @invitation.sender_id, friend_id: @user.id, status: 2)
          Friendship.create(user_id: @user.id, friend_id: @invitation.sender_id, status: 2)
        end
      end
      resource.save
      yield resource if block_given?
      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    else
      super
    end
  end

  def update
    super
  end

  #elsif Whitelist.exists?(:email => params[:user][:email].downcase)
  #super

  private

  def user_params
    params.require(:user).permit(:user_name, :birth_date, :email, :password, :password_confirmation)
  end

  def after_update_path_for(resource)
    dashboard_path
  end
end
