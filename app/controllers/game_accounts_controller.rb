class GameAccountsController < ApplicationController
  before_action :set_game_account, only: [:show, :edit, :update, :destroy]
  before_action :check_privileges!

  require 'net/http'
  require 'json'
  require 'uri'
  #clé api pour Rito
  # Ancienne clef API expirée = "ec8f092b-da94-4504-8f59-acdfc1d24e4b"
  API_KEY = "RGAPI-c8a60877-29ff-4e32-a3b7-1583bdd95e55"

  #Crud des comptes de jeu. Un compte de jeu appartien à un User. Seul un compte de jeu par utilisateur peut
  #être actif.

  # GET /game_accounts
  # GET /game_accounts.json
  def index
    #pas de raison que les modos y aient accès
    if can? :manage, GameAccount
      @game_accounts = GameAccount.all
    else
      redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
    end
  end

  # GET /game_accounts/1
  # GET /game_accounts/1.json
  def show
    if can? :destroy, User
      @user = current_user
      if @user.role.blank?
        redirect_to third_step_path
      end
    else
      redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
    end
  end

  # GET /game_accounts/new
  def new
    if can? :update, User
      @game_account = GameAccount.new
      @game_account.game_id = 1
      @user = current_user

      @activation_code = ('a'..'z').to_a.shuffle[0,8].join

    else
      redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
    end
  end

  # GET /game_accounts/1/edit
  def edit
    @user = current_user
    @game_account = GameAccount.find(params[:id])
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end

  # POST /game_accounts
  # POST /game_accounts.json
  def create
    @game_account = GameAccount.new(game_account_params)
    @user = current_user
    @game_account.user = @user
    @game_account.validated = false

    @unique = validate_uniqueness(@game_account.name)

    if @unique == 1

      @game_account.game_id = params[:game_account][:game]

      #LoL par défaut, sera bloqué par call api si besoin
      if params[:game].nil? and @game_account.game.nil?
        @game_account.game_id = 1
      elsif @game_account.game_id.nil?
        @game_account.game_id = params[:game]
      end

      if @game_account.p_role.nil?
        @game_account.p_role = @game_account.game.roles.first
      end

      get_game_rank(@game_account)

      if !@game_account.real_game_id.nil?
        if @user.state == 0 or @user.state == nil
          @user.game_accounts.each do |game_account|
            if game_account.active
              game_account.active = false
              game_account.save
            end
          end
          @game_account.active = true
        else
          @game_account.active = false
        end
      end

      @game_account.activation_code = params[:activation_code]

      @game_account.s_role = []
      if !params[:s_role].nil?
        @game_account.s_role = params[:s_role]
      end

      check_achievements(@user,"game_accounts")
    end

    respond_to do |format|
      if @game_account.real_game_id.nil? and @unique == 1
        #il y a un .save dans les update rank
        @game_account.destroy
        if @user.game_accounts.empty?
          format.html { redirect_to second_step_path, alert: 'Erreur : nom de compte incorrect' }
          format.js
        else
          format.html { redirect_to user_path(@user), alert: 'Erreur : nom de compte incorrect' }
          format.js
        end
      #real_game_id has to be nil if unique == 0
      elsif @game_account.real_game_id.nil?
        if @user.game_accounts.empty?
          format.html { redirect_to second_step_path, alert: 'Ce compte est déjà lié a un utilisateur' }
          format.js
        else
          format.html { redirect_to user_path(@user), alert: 'Ce compte est déjà lié a un utilisateur' }
          format.js
        end
      else
        if @game_account.save
          @user.game_accounts << @game_account
          @user.save
        #en cas de rollback
        elsif @game_account.update_attribute(:activation_code, params[:activation_code])
          @user.game_accounts << @game_account
          @user.save
        end
        # Mail de bienvenue aux joueurs ayant au moins un compte correct
        # & Validation des gems du parrainage si liaison d'un compte valide

        if @user.game_accounts.where.not(real_game_id: nil).count == 1
          NotificationsMailer.welcome(@user).deliver_now
          unless @user.parrain.nil?
            Notification.create(recepteur_id: @user.parrain, emetteur_id: @user.id, category:"friendship", action:"parrainage", notifiable: @user)
            wallet_manager(User.find(@user.parrain), nil, 75, "credit", "parrainage")
          end
        end
        format.html { redirect_to third_step_path }
        format.json { render :show, status: :created, location: @game_account }
        format.js
      end
    end
  end

  #pourrait être dans le modèle si le game_account n'était pas un tel casse-tête
  def validate_uniqueness(name)
    if GameAccount.where("replace(lower(name), ' ', '') LIKE ?", name.downcase.gsub(/\s+/, '')).exists?
      return 0
    end
    return 1
  end


  # PATCH/PUT /game_accounts/1
  # PATCH/PUT /game_accounts/1.json
  def update
    @user = current_user

    @game_account.s_role = []
    if !params[:s_role].nil?
      @game_account.s_role = params[:s_role]
    end

    respond_to do |format|
      if @game_account.update(game_account_params)
        format.html { redirect_to @user, notice: 'Game account was successfully updated.' }
        format.json { render :show, status: :ok, location: @game_account }
      else
        format.html { render :edit }
        format.json { render json: @game_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /game_accounts/1
  # DELETE /game_accounts/1.json
  def destroy
    @user = @game_account.user
    @game_account.destroy
    respond_to do |format|
      format.html { redirect_to @user, notice: 'Compte de jeu supprimé.' }
      format.json { head :no_content }
    end
  end

  def choose_game
    # @game = Game.find(params[:game_account][:game])
    @game = Game.find(params[:game])
    @game_account = GameAccount.new
    @game_account.game_id = @game.id
    respond_to do |format|
      format.js
    end
  end


  def second_step
    @user = current_user
    @activation_code = ('a'..'z').to_a.shuffle[0,8].join

    if @user.game_accounts.empty? or @user.game_accounts.where(:active => true).empty?
      @game_account = GameAccount.new
    else
      @game_account = @user.game_accounts.where(:active => true).first
      unless @game_account.name.blank?
        redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
      end
    end
  end

  def activate_game_account
    @user = User.find(params[:id])
    @game_account = GameAccount.find(params[:game_account])

    @user.game_accounts.each do |game_account|
      if game_account.active
        game_account.active = false
        game_account.save
      end
    end

    respond_to do |format|
      if @game_account.update_attribute(:active, true)
        get_game_rank(@game_account)
        format.html {redirect_to @user, notice: 'Compte de jeu activé.'}
        format.js
      else
        format.html {redirect_to @user, alert: 'Échec de l\'opération. Veuillez reessayer dans quelques instants.'}
        format.js
      end
    end
  end


  # Action de refresh via le dashboard, donc sur le compte actif
  def refresh
    @user = current_user
    get_game_rank(@user.account)
    check_achievements(@user,"game_accounts")

    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: 'Compte mis à jour.' }
      format.js
    end
  end

  # Action de refresh via users/:id, où tous les comptes de jeu de l'utilsateur sont visibles
  def refresh_account
    @account = GameAccount.find(params[:game_account])
    @user = User.find(params[:id])
    get_game_rank(@account)
    check_achievements(@account.user,"game_accounts")

    respond_to do |format|
      format.html { redirect_to @user, notice: 'Compte mis à jour.' }
      format.js
    end
  end

 #demande de l'id d'un compte à Rito
  def get_game_name_id(account)

    @account = account

    url = 'https://euw.api.pvp.net/api/lol/euw/v1.4/summoner/by-name/' + URI.encode(@account.name.gsub(/\s+/, "").downcase) + '?api_key=' + API_KEY
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)

    if !data["status"].blank?
      if data["status"]["status_code"] == 404
        return
      end
    end

    pseudo = @account.name.gsub(/\s+/, "").mb_chars.downcase.to_s

    @account.real_game_id = data[pseudo]["id"]
    @account.save

  end
  helper_method :get_game_name_id

  # Demande du rang d'un compte à Rito
  def get_game_rank(account)

    @account = account

    #need redirect to correct
    if @account.game_id == 2
      #à paufiner dans chaque objet Game ?
      get_ow_rank(@account)
      @account.save
      return
    elsif @account.game_id != 1
      @account.real_game_id = 0
      @account.save
      return
    end

    # On vérifie qu'on a le pseudo
    if @account.name.blank?
      return
    end

    # On va chercher l'id si on ne l'a pas encore
    if @account.real_game_id.blank?
      get_game_name_id(@account)
      @account.save
      if @account.real_game_id.blank?
        return
      end
    else
      # On vérifie que le pseudo n'a pas changé
      get_game_name(@account)
      @account.save
    end

    # Si le compte n'est pas unranked, on demande son rang
    game_id = @account.real_game_id.to_s
    url = 'https://euw.api.pvp.net/api/lol/euw/v2.5/league/by-summoner/' + game_id + '/entry?api_key=' + API_KEY
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)

    if (!data["status"].blank? && data["status"]["status_code"] == 404)
    	set_unranked(@account)
    	return
    end
    if data[game_id].blank?
    	set_unranked(@account)
    	return
    end


    if data[game_id][0]["queue"] == "RANKED_SOLO_5x5"
    	@account.tier = data[game_id][0]["tier"]
    	@account.division = data[game_id][0]["entries"][0]["division"]

  	elsif !data[game_id][1].blank?
        if data[game_id][1]["queue"] == "RANKED_SOLO_5x5"
          @account.tier = data[game_id][1]["tier"]
          @account.division = data[game_id][1]["entries"][0]["division"]

      	elsif !data[game_id][2].blank?
        	if data[game_id][2]["queue"] == "RANKED_SOLO_5x5"
	          @account.tier = data[game_id][2]["tier"]
	          @account.division = data[game_id][2]["entries"][0]["division"]
	        end
	    end
    end

    if data[game_id][0]["queue"] == "RANKED_FLEX_SR"
    	@account.flex_tier = data[game_id][0]["tier"]
    	@account.flex_division = data[game_id][0]["entries"][0]["division"]

  	elsif !data[game_id][1].blank?
        if data[game_id][1]["queue"] == "RANKED_FLEX_SR"
          	@account.flex_tier = data[game_id][1]["tier"]
          	@account.flex_division = data[game_id][1]["entries"][0]["division"]

      	elsif !data[game_id][2].blank?
        	if data[game_id][2]["queue"] == "RANKED_FLEX_SR"
	          	@account.flex_tier = data[game_id][2]["tier"]
	          	@account.flex_division = data[game_id][2]["entries"][0]["division"]
	        end
	    end
    end

	  @account.updated_at = Time.now.to_s
    @account.save

    set_mmr(@account)
  end
  helper_method :get_game_rank

  #demande du nom de compte à partir de l'id
  def get_game_name(account)

    @account = account

    url = 'https://euw.api.pvp.net/api/lol/euw/v1.4/summoner/'+@account.real_game_id.to_s+'?api_key=' + API_KEY
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)

    if !data["status"].blank?
      if data["status"]["status_code"] == 404
        return
      end
    end
    @account.name = data[ @account.real_game_id.to_s]["name"]
    @account.save
  end
  helper_method :get_game_name

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game_account
      @game_account = GameAccount.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_account_params
      params.require(:game_account).permit(:name, :p_role, :s_role, :activation_code, :gameplay)
    end

    def get_ow_rank(account)
      split = account.name.split('#');
      if split.length == 1
        return
      end
      pseudo = split[0]
      battleTag = split[1]

      url = 'http://ow-api.herokuapp.com/profile/pc/eu/'+URI.encode(pseudo)+'-'+battleTag
      uri = URI(url)
      response = Net::HTTP.get(uri)

      if response.nil? or response == "Not Found"
        return
      end

      data = JSON.parse(response)

      account.real_game_id = battleTag

      account.mmr = data["competitive"]["rank"]

      if account.mmr == 0 or account.mmr.nil?
        set_unranked(account)
      elsif account.mmr < 1500
        account.tier = "BRONZE"
      elsif account.mmr < 2000
        account.tier = "SILVER"
      elsif account.mmr < 2500
        account.tier = "GOLD"
      elsif account.mmr < 3000
        account.tier = "PLATINUM"
      elsif account.mmr < 3500
        account.tier = "DIAMOND"
      elsif account.mmr < 4000
        account.tier = "MASTER"
      else
        account.tier = "GRANDMASTER"
      end
      account.division = ""
      account.updated_at = Time.now.to_s
      account.save
    end


    def set_unranked(account)
    	account.tier = "unranked"
    	account.division = ""
    	account.flex_tier = "unranked"
    	account.flex_division = ""
    	set_mmr(account)
    	account.updated_at = Time.now.to_s
    	account.save
    end

    def set_mmr(account)

      @account = account
      @account.mmr = set_tier(@account.tier) + set_division(@account.division)
      @account.flex_mmr = set_tier(@account.flex_tier) + set_division(@account.flex_division)
      @account.save

    end

    def set_tier(tier)
    	tier_score = case tier
	        when "CHALLENGER" then 2200
	        when "MASTER" then 2000
	        when "DIAMOND" then 1800
	        when "PLATINUM" then 1600
	        when "GOLD" then 1400
	        when "SILVER" then 1200
	        when "BRONZE" then 1000
	        else 1000
	    end
	    return tier_score
    end

    def set_division(division)
    	div_score = case division
	        when "I" then 160
	        when "II" then 120
	        when "III" then 80
	        when "IV" then 40
	        when "V" then 0
	        else 0
	    end
	    return div_score
    end

end
