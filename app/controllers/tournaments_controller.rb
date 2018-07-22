class TournamentsController < ApplicationController
  before_action :set_tournament, except: [:index, :new, :create]

  def index
    @tournaments = Tournament.all
  end

  def show
    respond_to do |format|
      format.html { redirect_to dashboard_path, alert: "Cette fonctionnalité n'est disponible que dans un pop-up. Veuillez contacter un administrateur." }
      format.js
    end
  end

  def new
    @tournament = Tournament.new
  end

  def create
    @tournament = Tournament.new(tournaments_params)
    @tournament.save
    @tournaments = Tournament.all
    respond_to do |format|
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @tournament.update(tournaments_params)
    @tournaments = Tournament.all
    respond_to do |format|
      format.js
    end
  end

  def destroy
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def tournaments_params
    params.require(:tournament).permit(:name, :owner, :logo, :website, :vocal, :registration, :rules, :prizes, :map, :battle, :frequency, :day, :date, :hour, :mmr, :game_id)
  end

end
