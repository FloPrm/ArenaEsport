class PollsController < ApplicationController
  before_action :check_privileges!
  before_action :set_poll, only: [:show, :edit, :update, :destroy, :choices]
  before_action :set_polls, only: [:index, :tabs]
  respond_to :html, :js

  def show
  end

  def index
  end

  def new
    @poll = Poll.new
  end

  def create
    @poll = Poll.new(poll_params)
    @poll.user = current_user
    @poll.choices = ["", ""]
    @poll.language = ""
    if @poll.save
      redirect_to edit_poll_path(@poll)
    else
      redirect_to polls_path, alert: "Une erreur est survenue au moment de la création du sondage."
    end
  end

  def edit
    if current_user == @poll.user or (can? :manage, Article)
      @body_length = Poll.validators_on(:body).first.options[:maximum]
    else
      redirect_to @poll, alert: "Vous n'avez pas le droit d'éditer ce sondage."
    end
  end

  def update
    @poll.update(poll_params)
    @poll.choices = params[:poll][:choices]
    @poll.language = params[:poll][:language]
    if @poll.save
      redirect_to @poll
    else
      render :edit
    end
  end

  def destroy
    if @poll.destroy
      redirect_to polls_path, notice:"Le sondage a été supprimé avec succès."
    else
      redirect_to @poll, alert:"Une erreur est survenue au moment de supprimer le sondage."
    end
  end

  def tabs
  end

  def choices
    if params[:type] == "add"
      @poll.choices << ""
    elsif params[:type] == "remove"
      @poll.choices.delete_at(params[:choice].to_i)
    end
    @poll.save
  end

  private

  def poll_params
    params.require(:poll).permit(:title, :body, :choices, :featured, :result, :language)
  end

  def set_poll
    @poll = Poll.find(params[:id])
  end

  def set_polls
    @polls = Poll.all.paginate(:page => params[:page])
  end
end
