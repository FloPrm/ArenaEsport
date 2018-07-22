class WhitelistsController < ApplicationController
	before_action :check_privileges!, only: [:index]

	def index
		@search = Whitelist.search(params[:q])
		@whitelists = @search.result.paginate(:page => params[:page])
		@whitelist = Whitelist.new
	end

	def create
		@search = Whitelist.search(params[:q])
		@whitelists = @search.result
		@whitelist = Whitelist.create(whitelist_params)
		respond_to do |format|
			format.js
		end
	end

	def destroy
		@search = Whitelist.search(params[:q])
		@whitelists = @search.result
		@whitelist = Whitelist.find(params[:id])
		@whitelist.destroy
		respond_to do |format|
			format.js
		end
	end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def whitelist_params
      params.require(:whitelist).permit(:email)
    end

    def check_privileges!
      if !user_signed_in?
        redirect_to "/login", alert: 'Vous n\'avez pas accès à ce contenu.'
      elsif !can? :manage, User
        redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
      end
    end


end
