class HistoriesController < ApplicationController
  before_action :set_history, only: [:edit, :update, :destroy]

  def new
    @history = History.new
    @team = Team.find(params[:team])
    respond_to do |format|
      format.js
    end
  end

  def create
    @history = History.new(history_params)
    @history.user = current_user
    @team = Team.find(params[:team])
    @history.team = @team
    @history.save
    if @history.date > Time.now.to_date
      (@team.members - [current_user]).each do |player|
        Notification.create(emetteur:current_user, recepteur:player, category:"team", action:"history", notifiable:@team)
      end
    end
    check_achievements(@history.user,"histories")
    respond_to do |format|
      format.html { redirect_to @team, notice:"Événement créé avec succès." }
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @history.update(history_params)
    @team = @history.team
    respond_to do |format|
      format.html { redirect_to @team, notice:"Événement mis à jour." }
      format.js
    end
  end

  def destroy
    @team = @history.team
    @history.destroy
    respond_to do |format|
      format.js
    end
  end

  private

  def set_history
    @history = History.find(params[:id])
  end

  def history_params
    params.require(:history).permit(:date, :action, :content)
  end

end
