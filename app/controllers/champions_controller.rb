class ChampionsController < ApplicationController
  before_action :set_champion, only: [:show, :edit, :update, :destroy]
  before_action :check_privileges!, only: [:show, :edit, :index]

  # GET /champions
  # GET /champions.json
  def index
    @search = Champion.search(params[:q])
    @champions = @search.result
    @champion = Champion.new
  end

  # GET /champions/1/edit
  def edit
    respond_to do |format|
      format.js
    end
  end

  # POST /champions
  # POST /champions.json
  def create
    @search = Champion.search(params[:q])
    @champions = @search.result
    @champion = Champion.new(champion_params)
    respond_to do |format|
      if @champion.save
        format.html { redirect_to @champion, notice: 'Champion was successfully created.' }
        format.json { render :show, status: :created, location: @champion }
        format.js
      else
        format.html { render :new }
        format.json { render json: @champion.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # PATCH/PUT /champions/1
  # PATCH/PUT /champions/1.json
  def update
    @search = Champion.search(params[:q])
    @champions = @search.result
    respond_to do |format|
      if @champion.update(champion_params)
        format.html { redirect_to @champion, notice: 'Champion was successfully updated.' }
        format.json { render :show, status: :ok, location: @champion }
        format.js
      else
        format.html { render :edit }
        format.json { render json: @champion.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /champions/1
  # DELETE /champions/1.json
  def destroy
    @search = Champion.search(params[:q])
    @champions = @search.result
    @champion.destroy
    respond_to do |format|
      format.html { redirect_to champions_url, notice: 'Champion was successfully destroyed.' }
      format.json { head :no_content }
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_champion
      @champion = Champion.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def champion_params
      params.require(:champion).permit(:name, :icon, :game_id)
    end

    def check_privileges!
      if !user_signed_in?
        redirect_to "/login", alert: 'Vous n\'avez pas accès à ce contenu.'
      elsif !can? :manage, User
        redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
      end
    end
end
