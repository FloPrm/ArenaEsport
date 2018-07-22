class GamesController < ApplicationController
  before_action :set_game, only: [:show, :rate_modal, :rate, :edit, :update, :destroy]
  before_action :set_all, only: [:mostplayed, :rate, :create, :update, :destroy]
  before_action :set_user, only: [:rate]
  before_action :set_tournament, only: [:rate_modal, :rate]
  respond_to :html, :js


  # GET /games
  # GET /games.json
  def index
    @search = Game.search(params[:q])
    @games = @search.result
    @search.build_condition
  end

  def mostplayed
  end

  # GET /games/1
  # GET /games/1.json
  def show
  end

  # GET /games/new
  def new
    @game = Game.new
  end

  # GET /games/1/edit
  def edit
  end

  # POST /games
  # POST /games.json
  def create
    @game = Game.new(game_params)

    respond_to do |format|
      if @game.save
        format.html { redirect_to @game, notice: 'Game was successfully created.' }
        format.json { render :show, status: :created, location: @game }
        format.js
      else
        format.html { render :new }
        format.json { render json: @game.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
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

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    @game.destroy
    respond_to do |format|
      format.html { redirect_to games_url, notice: 'Game was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def rate_modal
    respond_to do |format|
      format.html
      format.js
    end
  end

  def rate
    @rating = Rating.new(rating_params)
    @rating.game_id = @game.id
    @rating.user_id = @user.id
    @rating.save
      respond_to do |format|
      format.html { redirect_to games_url, notice: 'Rating was successfully sent.' }
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    def set_all
      @games = Game.all
    end

    def set_user
      @user = current_user
    end

    def set_tournament
      @tournament = Tournament.find(params[:tournament_id])
    end

    def rating_params
      params.require(rate_modal_game_path).permit(:rating)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.require(:game).permit(:name, :description, :pegi)
    end
end
