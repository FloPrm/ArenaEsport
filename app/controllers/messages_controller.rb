class MessagesController < ApplicationController
  before_action :authenticate_user!
  respond_to :html, :js

  def index
    authorize! :manage, Article
    @search = Message.search(params[:q])
    @messages = @search.result.paginate(:page => params[:page])
  end

  def create
    @team = Team.find(params[:team])
    @user = current_user
    @message = Message.new(messages_params)
    @message.user = @user
    @message.team = @team
    @message.save
  end

  def destroy
    @search = Message.search(params[:q])
    @messages = @search.result.paginate(:page => params[:page])
    @message = Message.find(params[:id])
    @team = @message.team
    @id = @message.id
    @message.destroy
  end

  private

  def messages_params
    params.require(:message).permit(:body)
  end
end
