class KarmasController < ApplicationController
  respond_to :html, :js

  def index
    @search = Karma.search(params[:q])
    @karmas = @search.result.paginate(:page => params[:page])
  end

  def new
    @karma = Karma.new
  end

  def create
    @user = User.find(params[:karma][:voted_id])
    @karma = Karma.create(karma_params)
  end

  private

  def karma_params
    params.require(:karma).permit(:voter_id, :voted_id, :vote, :comment)
  end

end
