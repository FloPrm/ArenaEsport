class GamesController < ApplicationController
  before_action :set_game, except: [:index, :new]
  before_action :check_privileges!

  # GET /games
  # GET /games.json
  def index
    authorize! :manage, :all
    @games = Game.all
  end

  # GET /games/1
  # GET /games/1.json
  def show
    authorize! :manage, :all
    @users = User.joins(:game_accounts).where(:game_accounts => {game_id: @game.id})
    @percent_u = 100 * @users.count / User.joins(:game_accounts).count
    @teams = Team.where(game_id: @game.id)
    @percent_t = 100 * @teams.count / Team.count
  end

  # GET /games/new
  def new
    authorize! :manage, :all
    @game = Game.new
  end

  # GET /games/1/edit
  def edit
    authorize! :manage, :all
  end

  # POST /games
  # POST /games.json
  def create
    authorize! :manage, :all
    @game = Game.new(game_params)
    @game.roles = ["",""]
    if @game.save
      redirect_to edit_game_path(@game)
    else
      render :new
    end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
    authorize! :manage, :all
    respond_to do |format|
      if @game.update(game_params)
        format.html { redirect_to @game, notice: 'Game was successfully updated.' }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  def roles
    if params[:type] == "add"
      @game.roles << ""
    elsif params[:type] == "remove"
      @game.roles.delete_at(params[:num_role].to_i)
    end
    @game.save
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    authorize! :manage, :all
    @game.destroy
    respond_to do |format|
      format.html { redirect_to games_url, notice: 'Game was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.require(:game).permit(:title, :active, :nb_players, :roles, :has_soloq, :has_teamq, :adaptable, :compositions, :compo_bans, :characters, :player_name, :character_name, :mentorat_mmr, :discord, :discord_eu)
    end

    def check_privileges!
      if !user_signed_in?
        redirect_to "/login", alert: 'Vous n\'avez pas accès à ce contenu.'
      elsif !can? :manage, :all
        redirect_to "/", alert: 'Vous n\'avez pas accès à ce contenu.'
      end
    end

end
