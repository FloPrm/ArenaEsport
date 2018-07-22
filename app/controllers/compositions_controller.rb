class CompositionsController < ApplicationController
  before_action :set_composition, except: [:index, :new, :create]
  before_action :set_champions, only: [:add_champion, :remove_champion, :ratio]
  respond_to :js

  def index
    authorize! :manage, :all
    @compositions = Composition.all.paginate(:page => params[:page])
  end

  def new
    @team = Team.find(params[:team])
    @composition = Composition.new
    respond_to do |format|
      format.html { redirect_to @team, alert: "Une erreur est survenue lors de l'ouverture de la fenêtre de création de composition."}
      format.js
    end
  end

  def create
    @team = Team.find(params[:team])
    @composition = Composition.new(composition_params)
    @composition.team_id = params[:team]
    @composition.picks = Array.new(@composition.team.game.nb_players, nil)
    @composition.bans = [nil, nil, nil]
    # Partial variables
    @champions = Champion.where(game_id:@team.game_id).pluck(:name)
    @composition.save
    respond_to do |format|
      format.html { redirect_to @team, notice: "Composition créée avec succès." }
      format.js
    end
  end

  def add_champion
    num_champ = params[:num_champ].to_i
    champion = params[:champion].downcase
    if params[:type] == "pick"
      @composition.picks[num_champ] = champion
    elsif params[:type] == "ban"
      @composition.bans[num_champ] = champion
    end
    @composition.save
  end

  def remove_champion
    num_champ = params[:num_champ].to_i
    if params[:type] == "pick"
      @composition.picks[num_champ] = nil
    elsif params[:type] == "ban"
      @composition.bans[num_champ] = nil
    end
    @composition.save
  end

  def ratio
    if params[:type] == "win-up"
      @composition.win += 1
    elsif params[:type] == "win-down"
      @composition.win -= 1
    elsif params[:type] == "lose-up"
      @composition.lose += 1
    elsif params[:type] == "lose-down"
      @composition.lose -= 1
    end
    @composition.save
  end

  def edit
  end

  def update
    @composition.update(composition_params)
  end

  def destroy
    @team = @composition.team
    if @composition.destroy
      redirect_to compositions_path, notice: "Composition supprimée avec succès."
    else
      redirect_to compositions_path, alert: "Une erreur s'est produite."
    end
  end

  private

  def set_composition
    @composition = Composition.find(params[:id])
  end

  def set_champions
    @champions = Champion.where(game_id:@composition.team.game_id).pluck(:name)
  end

  def composition_params
    params.require(:composition).permit(:title)
  end
end
