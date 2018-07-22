class UsersController < ApplicationController
	#before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :check_privileges!
  include UsersHelper

	def show
  	@user = User.find(params[:id])
    @account = @user.game_accounts.where(:active => true).first

    unless @account.nil?
      if @account.champions.blank?
        @account.champions = []
        @account.save
      end
    end

  	@hash = Gmaps4rails.build_markers(@user) do |user, marker|
  		marker.lat user.latitude
  		marker.lng user.longitude
  	end

    if @user.role.blank?
      @user.role = "standard"
      @user.save
    end
	end

	def user_preview
    @user = User.find(params[:id])
    @account = @user.account
    if params[:team_application].present?
      @team_application = TeamApplication.find(params[:team_application])
    end
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end

  def avatar_modal
    @user = current_user
    unless can? :manage, Champion
      @images = Dir.glob("app/assets/images/icons/*").sort - Dir.glob("app/assets/images/icons/*premium*")
    else
      @images = Dir.glob("app/assets/images/icons/*").sort
    end
    respond_to do |format|
      format.html { redirect_to edit_user_registration_path(@user), alert: t('alerts.error') }
      format.js
    end
  end

  def avatar
    @user = current_user
    @user.update_column(:icon, params[:icon])
    unless @user.avatar.nil?
      @user.remove_avatar!
    end
    @user.save
    respond_to do |format|
      format.js
    end
  end

	def index
    if can? :manage, Article
			@search = User.search(params[:q])
		  @users = @search.result.includes(:account).paginate(:page => params[:page])
			respond_to do |format|
        format.html
        format.js
      end
    else
      redirect_to root_path, alert: t('alerts.restricted_content')
    end
	end

  def parrainages
    @users = User.where.not(parrain:nil).paginate(:page => params[:page], :per_page => 20)
  end

	def edit
    if (can? :update, User) or (can? :manage, Article)
      #Filtre droits > standard ou propre compte
      @users = User.all
      @user = User.find(params[:id])
      if (can? :manage, Article) or current_user == @user

        @game_account = @user.game_accounts.where(:active => true).first
        if @game_account.game.characters == true
          @champions = Champion.where(game_id: @game_account.game_id).pluck(:name)
        end

        if @game_account.nil?
          redirect_to second_step_path, alert: t('game_accounts.alerts.valid_account')
  				return
        elsif @game_account.real_game_id.nil?
          redirect_to dashboard_path, alert: t('game_accounts.alerts.valid_account')
  				return
        end
  			@maximum_length = GameAccount.validators_on( :autre ).first.options[:maximum]
      else
        redirect_to dashboard_path, alert: t('alerts.restricted_content')
        return
      end
    else
      if current_user.game_accounts.empty?
        redirect_to dashboard_path, alert: t('alerts.restricted_content')
				return
      else
				#redirect_to edit_user_path
        redirect_to third_step_path
				return
      end
    end
		respond_to do |format|
			format.html
			format.js
		end
	end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    @user = User.find(params[:id])
    @account = @user.game_accounts.where(:active => true).first
		@team = Team.joins(:teamings).where(:teamings => { user_id: @user.id, active: true}).first

    @user.week_start = params[:user][:week_start]
    @user.week_end = params[:user][:week_end]
    @user.we_start = params[:user][:we_start]
    @user.we_end = params[:user][:we_end]
		@user.horaire = params[:user][:horaire]
		@user.skype = params[:user][:skype]
    @user.discord = params[:user][:discord]
    @user.admin_note = params[:user][:admin_note]
    @user.lang_p = params[:user][:lang_p]

    if !params[:game_account].nil?
      @account.p_role = params[:game_account][:p_role]
    end

		@account.s_role = []
    if !params[:s_role].nil?
      @account.s_role = params[:s_role]
    end

    if !params[:objectifs].nil?
      @account.objectifs = params[:objectifs]
    end

    if @user.role.blank?
      @user.role = "standard"
    end

    if @user.state == 0 or @user.state == 1
      @teaming = @user.teamings.where(active:true).first
      if @teaming.present?
        roles = [@account.p_role] + @account.s_role
        if !roles.include?(@teaming.role)
          @team = @teaming.team
          @team.u_count -= 1
          @team.players[@teaming.num_role] = 0
          @team.save
          @teaming.destroy
        end
      end
    end
=begin
		if @user.premade.present?
			@user.premades.each do |premade|
				if premade.user.state == 0
					premade.user.state = 1
          premade.user.date_search = Time.now.to_s
          premade.user.save
				end
			end
		end

    if @user.state == 0 or @user.state == 1
      @user.state = 1
      @user.date_search = Time.now.to_s
      @teaming = @user.teamings.where(active:true).first
      if @teaming.present?
        roles = [@account.p_role] + @account.s_role
        if !roles.include?(@teaming.role)
          @team = @teaming.team
          @team.u_count -= 1
          @team.players[@teaming.num_role] = 0
          @team.save
          @teaming.destroy
        end
      end
    end
=end
		@account.gameplay = params[:game_account][:gameplay]
		@account.autre = params[:game_account][:autre]

    check_achievements(@user,"users")

    respond_to do |format|
      if @user.save
        @account.save
        unless (@user.week_start + @user.week_end + @user.we_start + @user.we_end) == 0
          format.html { redirect_to dashboard_path, notice: t('users.notices.update') }
        else
          format.html { redirect_to edit_user_path(@user), alert: t('users.alerts.availabilities') }
        end
        format.json { render :show, status: :ok, location: @user }
				format.js
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
				format.js
      end
    end
  end

  def search_team
    @user = User.find(params[:id])
    @account = @user.account
    User.transaction do
      if @account.real_game_id.nil?
        redirect_to dashboard_path, alert: t('users.alerts.valid_account')
      elsif (@account.tier == "unranked" or @account.tier.blank?) && (@account.flex_tier == "unranked" or @account.flex_tier.blank?)
        redirect_to dashboard_path, alert: t('users.alerts.ranked')
      elsif (@user.week_start + @user.week_end + @user.we_start + @user.we_end) == 0
        redirect_to dashboard_path, alert: t('users.alerts.availabilities')
      elsif !(@user.can? :update, User)
        redirect_to dashboard_path, alert: t('alerts.banned_action')
      else
        if @user.premade.present?
    			@user.premades.each do |premade|
    				if premade.user.state == 0
    					premade.user.state = 1
              premade.user.date_search = Time.now.to_s
              premade.user.save
    				end
    			end
    		end

        if @user.state == 0
          @user.state = 1
          @user.date_search = Time.now.to_s
        end

        check_achievements(@user,"users")

        respond_to do |format|
          if @user.save
            format.html { redirect_to dashboard_path, notice: t('users.notices.search_team') }
            format.js
          else
            format.html { redirect_to dashboard_path, alert: t('alerts.error') }
            format.js
          end
        end # respond_to block
      end # if else check conditions
    end # transaction
  end

	def add_champion
		@user = User.find(params[:id])
		@champion = params[:champion]
		@game_account = @user.account

		@names = Champion.pluck(:name).to_s.downcase

    if !@champion.nil? and @names.include?(@champion)
      @game_account.champions << @champion
			@game_account.save
    end

		respond_to do |format|
			format.js
		end
	end

	def remove_champion
		@user = User.find(params[:id])
		@champion = params[:champion]
		@game_account = @user.account

		@game_account.champions.delete(@champion)
		@game_account.save

		respond_to do |format|
			format.js
		end
	end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def dashboard

		@user = current_user

    check_subscription(@user)

		if @user.game_accounts.where(active:true).empty?
			redirect_to second_step_path
		end

    @account = @user.account

    if @user.teamings.where(:active => true).empty?
      @team = nil
    else
      @teaming = Teaming.where(:user_id => @user.id).where(:active => true).first
      @team = Team.joins(:teamings).merge(Teaming.where(:id => @teaming.id).where(:active => true)).first
			@joueurs = User.joins(:teamings).where(:teamings => { team_id: @team.id, active: true })

			@game_accounts = []
			@joueurs.each do |joueur|
			  @game_accounts << GameAccount.where(user_id: joueur.id, active: true).first
			end
			@min = @game_accounts.sort_by(&:"#{:mmr}").first
			@max = @game_accounts.sort_by(&:"#{:mmr}").last
    end

    if @user.mentor.present?
      @actifs = User.joins(:mentorat).where(:mentorats => {mentor_id: @user.mentor.id, status: 1})
      @actifs_t = Team.joins(:mentorat).where(:mentorats => {mentor_id: @user.mentor.id, status: 1})
      @students = (User.joins(:mentorat).where(:mentorats => {mentor_id: @user.mentor.id, status: 1}) + User.joins(:seances).where(:seances => {mentor_id: @user.mentor.id, status: 1})).uniq
      # Important : @seances ne doit pas inclure les séance dont le "status" est 0 = en attente de validation
      @seances = @user.mentor.seances
      @hours = @user.mentor.seances.where(status:1).pluck(:duration).inject(:+)/60 unless !@user.mentor.seances.where(status:1).present?
    end
    unless current_user.account.nil?
      @tournaments = Tournament.where(game_id: @user.account.game_id)
    else
      @tournaments = Tournament.all
    end
  end

  #third part of sign_up
  def third_step
		@user = current_user
		@game_account = @user.game_accounts.where(active:true).first
    if @game_account.game.characters == true
      @champions = Champion.where(game_id: @game_account.game_id).pluck(:name)
    end
		@maximum_length = GameAccount.validators_on( :autre ).first.options[:maximum]

    if @game_account.game_id.nil?
      redirect_to dashboard_path, alert: t('users.alerts.valid_account')
    end
  end


  def searching_team
    @user = current_user
    @account = @user.game_accounts.where(:active => true).first
  end

  def leave_search_modal
    respond_to do |format|
      format.js
    end
  end

  def leave_search
    User.transaction do
      @user = current_user
      leave_search_process(@user)
      if @user.premade.present?
        if !params[leave_search_modal_user_path].nil? && params[leave_search_modal_user_path][:premade] == "false"
          leave_premade(@user, "leave-search")
        else
          @user.premades.each do |premade|
            leave_search_process(premade.user)
          end
        end
      end
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: 'Sorti de la recherche d\'équipe.' }
      end
    end
  end

  def edit_role_modal
    authorize! :manage, :all
		@user = User.new
		@user = User.find(params[:id])
    respond_to do |format|
      format.html { redirect_to users_path }
      format.js
    end
  end

	def edit_role
		@users = User.all
		@user = User.find(params[:id])
		@user.update_column(:role, params[:user][:role])
		@user.save
		respond_to do |format|
      format.html { redirect_to users_path }
      format.js
		end
	end

  def edit_state
    @users = User.all
    @user = User.find(params[:id])
    if @user.state == 0
      @user.state = 1
      @user.date_search = Time.now.to_s
      if @user.premade.present?
        @user.premades.each do |premade|
          premade.user.state = 1
          premade.user.date_search = Time.now.to_s
          premade.user.save
        end
      end
    elsif @user.state == 1
      @user.state = 0
      if @user.premade.present?
        @user.premades.each do |premade|
          premade.user.update_attribute(:state, 0)
        end
      end
    end
    @user.save
    respond_to do |format|
      format.html { redirect_to users_path }
      format.js
		end
  end

  def change_language
    @user = User.find(params[:id])
    if @user.update_attribute(:language,params[:lang])
      @url = params[:url].gsub("/#{params[:locale]}/","/#{params[:lang][0..1]}/")
      redirect_to @url
    else
      redirect_to params[:url]
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    #def set_user
    #  @user = User.find(params[:id])
    #end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:user_name, :email, :first_name, :last_name, :birth_date, :role, :week_start, :week_end, :we_start, :we_end, :avatar, :horaire, :skype, :lang_p, :lang_s)
    end

    def leave_search_process(user)
      @user = user
      @user.state = 0
      if @user.teamings.where(active: true).present?
        @teaming = @user.teamings.where(active:true).first
        @team = @teaming.team
        @team.players[@teaming.num_role] = 0
        @team.u_count -= 1
        @team.save!
        @teaming.destroy!
      end
      @user.save!
    end
end
