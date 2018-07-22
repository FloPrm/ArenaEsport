class TeamsController < ApplicationController
  before_action :check_privileges!
  before_action :set_team, except: [:index, :new, :create, :user_preview]
  include TeamsHelper

  # GET /teams
  # GET /teams.json
  def index
    if can? :manage, Article
      @search = Team.search(params[:q])
		  @teams = @search.result
    else
      redirect_to dashboard_path
      # alert: 'Vous n\'avez pas accès à ce contenu.'
    end
  end

  # GET /teams/1
  # GET /teams/1.json
  def show
    if current_user.teamings.where(team_id: @team.id, active:true).present? or (can? :manage, Article) or (current_user.mentor.present? && @team.mentorat.present? && @team.mentorat.mentor.user == current_user)

    else
      redirect_to dashboard_path, alert: 'Vous n\'avez pas accès à ce contenu.'
    end

    @user = current_user
    @joueurs = User.joins(:teamings).where(:teamings => { team_id: @team.id, active: true })
    @asker = @team.teamings.where(active: true, swap: current_user.teamings.where(active:true)).first
    @asked = @user.teamings.where(active: true).first
    @election = @team.votes.where(action:"élection").last

    # Horaire commun semaine & weekend
    @week_starts = @joueurs.pluck(:week_start)
    @week_ends = @joueurs.pluck(:week_end)
    @we_starts = @joueurs.pluck(:we_start)
    @we_ends = @joueurs.pluck(:we_end)

    @champions = Champion.where(game_id: @team.game_id).pluck(:name)
    @tournaments = Tournament.where(game_id: @team.game_id)
    @events = @team.histories.joins(:user).where(date: Time.now.beginning_of_week..Time.now.end_of_week).order('date ASC')
    # définit le mmr le plus élevé dans l'équipe pour trier les tournois recommandés
    @game_accounts = @team.accounts
    @mmr = (@game_accounts.pluck(:mmr) + @game_accounts.pluck(:flex_mmr)).reject(&:nil?).sort.last

    @role = params[:role]
    @statut = params[:statut]
    @count = nil

    @countries = @team.members.pluck(:country).uniq

    @users_list = User.all
  end

  def preview
    @team = Team.find(params[:id])
    @joueurs = @team.members
    @week_starts = @joueurs.pluck(:week_start)
    @week_ends = @joueurs.pluck(:week_end)
    @we_starts = @joueurs.pluck(:we_start)
    @we_ends = @joueurs.pluck(:we_end)
    respond_to do |format|
      format.html { redirect_to dashboard_path, alert: "Problème de chargement de la fenêtre de prévisualisation d'équipe."}
      format.js
    end
  end

  # GET /teams/new
  def new
    @team = Team.new
    respond_to do |format|
      format.html { redirect_to dashboard_path, alert: "Problème lors de l'ouverture de la fenêtre de création d'équipe." }
      format.js
    end
  end

  # GET /teams/1/edit
  def edit
    if can? :manage, Team
      @team = Team.find(params[:id])
      respond_to do |format|
        format.js
      end
    else
      redirect_to dashboard_path, alert: 'Vous n\'avez pas accès à ce contenu.'
    end
  end

  # POST /teams
  # POST /teams.json
  def create
    if current_user.can? :update, User
      @team = Team.new(team_params)

      #si les roles ne sont pas changeables (modèle LoL), on prend l'ordre du jeu
      if !@team.game.adaptable
        @team.roles = @team.game.roles
      else
        @team.roles = Array.new(@team.game.nb_players, @team.game.roles.first)
      end

      unless can? :manage, :all
        @user = current_user
        if @user.team_applications.present?
          @user.team_applications.destroy_all
        end
        if @user.pending_invitations.present?
          @user.pending_invitations.destroy_all
        end
        role = @user.account.p_role
        @teaming = Teaming.create(user: @user, team: @team, role: role, active: true)
        Planning.create(user: @user, team: @team)
        @user.state = 2
        if @team.game.adaptable
          @team.roles[0] = role
        end
        @team.players = Array.new(@team.game.nb_players, 1)
        num_role = @team.roles.index(role)
        @teaming.update_attribute(:num_role,num_role)
        if !num_role.nil?
          @team.players[num_role] = 2
        end
        @team.start_date = Time.now.to_s
        @team.u_count += 1
        History.create(date: Time.now, team: @team, action:"creation")
      else
        @team.players = Array.new(@team.game.nb_players, 0) #=> si nb_players = 3,  [0, 0, 0]
      end

      respond_to do |format|
        if @team.save
          if @team.name.empty?
            id = @team.id.to_s
            @team.update_attribute(:name, id)
          end
          @user.save unless @user.nil?
          format.html { redirect_to @team, notice: 'Equipe créée avec succès.' }
          format.js
        else
          format.html { render :new }
          format.js
        end
      end
    else
      redirect_to dashboard_path, alert: t('alerts.banned_action')
    end
  end

  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
  def update
    @team.update(team_params)
    max = @team.game.nb_players
    for i in 0..(max -1) do
      @team.roles[i] = params[:team][:roles][i]
    end
    @team.save
    respond_to do |format|
      if can? :manage, :all
        format.html { redirect_to teams_path, notice: 'Equipe mise à jour avec succès.' }
        format.json { render :show, status: :ok, location: @team }
      else
        format.html { redirect_to @team, notice: 'Equipe mise à jour avec succès.' }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /teams/1
  # DELETE /teams/1.json
  def destroy
    @team.destroy
    respond_to do |format|
      format.html { redirect_to teams_url, notice: 'Equipe supprimée avec succès.' }
      format.json { head :no_content }
    end
  end

  def modify_modal
    respond_to do |format|
      format.html { }
      format.js
    end
  end

  def modify
    @team.name = params[:team][:name]
    @team.save
    respond_to do |format|
      format.html { redirect_to @team, notice: "Equipe modifiée avec succès." }
      format.js
    end
  end

  def team_builder
    if can? :manage, Team
      @team = Team.find(params[:id])

      @role = nil
      #@statut = params[:statut]
      @count = nil

      @users_list = User.all
    else
      redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
    end
  end

  # Ajout d'un utilisateur à une équipe, à un rôle donné
  def add_user
    Team.transaction do
      @users = User.all
      @users_list = User.all

      role = params[:role]
      num_role = params[:num_role].to_i
      if params[:user].present?
        @user = User.find(params[:user])
      elsif params[:account].present?
        @account = GameAccount.where(game_id:@team.game_id).where("replace(lower(name), ' ', '') LIKE ?", params[:account].downcase.gsub(/\s+/, '')).first
        unless @account.nil?
          @user = @account.user
        end
      end
      if @user.nil?
        respond_to do |format|
          format.js { flash[:add_user] = "Joueur introuvable." }
        end
      elsif @user.state == 2
        respond_to do |format|
          format.js { flash[:add_user] = "Joueur déjà en team." }
        end
      else
        add_user_process(@team, @user, role, num_role)
        respond_to do |format|
          format.html { redirect_to @team, notice: 'Joueur inscrit'}
          format.json {head :no_content}
          format.js
        end
      end
    end
  end

  #joueur retiré de l'équipe
  def remove_user
    Team.transaction do
      @users = User.all
      @users_list = User.all
      @user = User.find(params[:user])
      @teamings = @team.teamings.joins(:user).where(active: true)
      @reason = params[leave_modal_team_path][:reason] unless params[leave_modal_team_path].nil?

      # Peut-être ajouter une vérif pour s'assurer qu'il n'y a pas eu plusieurs entrées dans l'équipe
      @teaming = Teaming.where(user_id: @user.id, team_id: @team.id, active: true).first
      if !@reason.nil?
        @teaming.reason = @reason
      end

      if @team.votes.where(votable:@user, action:"élection", result:nil).exists?
        @team.votes.where(votable:@user, action:"élection", result:nil).first.destroy!
      end

      if @teaming.active = true
        @teaming.active = false
        @teaming.end_date = Time.now.to_s
        @teaming.save!

        # Désigne un capitaine random si le joueur était capitaine
        if @teaming.captain == "true"
          @new_captain = @team.teamings.where(active:true).where.not(id: @teaming.id).first
          @new_captain.update_attribute(:captain,true)
        end

        # Actualise l'état de disponibilité du rôle. 1 = vide mais pas de demande de remplacement.
        # La demande de rempacement se fait par une fonction séparée de tofit.
        num_role = @teaming.num_role
        unless @team.start_date.nil?
          if !num_role.nil?
            @team.players[num_role] = 1
          end
        else
          if !num_role.nil?
            @team.players[num_role] = 0
          end
        end

        # Si le joueur était membre, il devient sans team. Sinon, il s'agit d'un ajout non validé du recruteur.
        # Il ne faut donc pas que l'utilisateur soit forcé de se remettre en recherche. Son état reste donc inchangé.
        if @user.state == 2
          @user.update_attribute(:state, 0)
          if @user.premade.present?
            if !params[leave_modal_team_path].nil? && params[leave_modal_team_path][:premade] == "false"
              leave_premade(@user, "leave-team")
            else
              @user.premades.each do |premade|
                if premade.user.teamings.where(active:true, team_id: @team.id).present?
                  premade.user.update_attribute(:state, 0)
                  teaming = premade.user.teamings.where(active:true, team_id: @team.id).last
                  teaming.active = false
                  teaming.end_date = Time.now.to_s
                  teaming.reason = @reason
                  teaming.save!
                  @team.players[teaming.num_role] = 1
                  @team.u_count -=1
                  History.create(date: Time.now, team: @team, teaming: teaming, action:"member-leave")
                end
              end
            end
          end
          if @user != current_user
            History.create(date: Time.now, team: @team, teaming: @teaming, action:"exclusion")
            Notification.create(recepteur: @user, emetteur: current_user, category: "team", action: "exclusion")
          else
            @joueurs = User.joins(:teamings).where(:teamings => { team_id: @team.id, active: true })
            (@joueurs - [current_user]).each do |joueur|
              Notification.create(recepteur: joueur, emetteur: current_user, category: "team", action: "départ", notifiable: @team)
            end
            History.create(date: Time.now, team: @team, teaming: current_user.teamings.last, action:"member-leave")
          end
        else
          @teaming.destroy!
        end

        @team.u_count -=1

        # Dissolution si il y a moins de la moitier des joueurs requis après le départ d'une premade notamment
        if !@team.start_date.nil? && @team.members.count < (@team.game.nb_players / 2).floor + 1
          dissolution_process(@team)
        end
        @team.save!
      end
      check_achievements(@user,"teams")

      if(current_user != @user)
        respond_to do |format|
            format.html { redirect_to @team, notice: "Le joueur a bien été retiré de l'équipe." }
            format.json {head :no_content}
            format.js
        end
      else
        redirect_to dashboard_path
      end
    end
  end

  def change_role
    role = params[:change].split('-').first
    num_role = params[:change].split('-').last.to_i
    unless @team.players[num_role] == 2 or @team.invitations.where(num_role: num_role).exists?
      @team.roles[num_role] = role
      @team.save
      respond_to do |format|
        format.js
      end
    else
      redirect_to @team, alert: "Impossible de changer le rôle lorsque des invitations sont en attente."
    end
  end

  def leave_modal
    @user = User.find(params[:user])
    @premades = []
    if @user.premade.present?
      @user.premades.each do |premade|
        if premade.user.teamings.where(active:true, team_id: @team.id).present?
          @premades << premade.user
        end
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def dissolution_modal
    @user = User.find(params[:user])
    respond_to do |format|
      format.js
    end
  end

  #liste des joueurs en recherche pour un rôle donné en premier et second rôle
  def listing
    @role = params[:role].downcase
    @num_role = params[:num_role].to_i
    @m_count = @team.members.count
    if @m_count > 0
      # Verificateurs seconds rôles
      @count_snd = 0
      @team.members.each do |player|
        unless player.account.p_role == player.teamings.where(active:true).first.role
          @count_snd += 1
        end
      end
      @max_snd = (@team.game.nb_players / 2).floor
      # Verificateurs rank
      @game_accounts = @team.accounts
      if @team.game.has_teamq
        @team_min = @game_accounts.sort_by(&:"#{:flex_mmr}").first
        @team_max = @game_accounts.sort_by(&:"#{:flex_mmr}").last
      else
        @team_min = @game_accounts.sort_by(&:"#{:mmr}").first
        @team_max = @game_accounts.sort_by(&:"#{:mmr}").last
      end
      # Verificateurs age
      @ages = @team.members.pluck(:birth_date).map{|d| d.find_age}
      ta = simplify_age((@ages.inject(0.0) { |sum, el| sum + el } / @ages.size).to_i)
      # Verificateurs horaires
      @team_start = @team.members.pluck(:week_start).sort.last
      @team_end = @team.members.pluck(:week_end).sort.first
      @we = @team.members.where(week_start: 0).present? or @team.members.where(week_end: 0).present? ? true : false
      # Langue
      languages = @team.members.pluck(:lang_p)
      freq = languages.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
      lang = languages.max_by { |v| freq[v] }
    end

    @users_list_p = []
    @users_list_s = []
    if @role != ""
      @search = User.searching.joins(:account).where(:game_accounts => {game_id: @team.game_id}).order(:date_search).search(params[:q])
      @users =  @search.result - @team.blacklisted
      @users.each do |user|
        account = user.account
        ps = user.week_start
        pe = user.week_end
        pa = simplify_age(user.birth_date.find_age)
        if account.game.has_teamq
          mmr = account.flex_mmr
        else
          mmr = account.mmr
        end
        if @m_count > 0
          if @team_start < ps
          	@start = ps
          else
            @start = @team_start
          end
          if @team_end > pe
          	@end = pe
          else
            @end = @team_end
          end
        end

        if !account.nil?
          if account.p_role == @role
            if @m_count > 0
              if !user.teamings.where(team_id: @team.id).empty?
                # Vérifier si le joueur n'a pas déjà fait partie de l'équipe
              elsif @team.members.count < 3 && user.teamings.where(active:true).present?
                # Retire les joueurs déjà en préteam si l'équipe ne contient pas plus de la moitier des joueurs requis
              elsif account_rank_gap?(@team_min, account) or account_rank_gap?(@team_max, account)
                # Vérifier si l'écart de niveau n'est pas trop important avec le premier et/ou le dernier joueur de l'équipe
              elsif (@we == false && (@end - @start < 2))
                # Vérifier si il y a au moins 2 heures en commun
                # Add : or (@we == true && ps + pe > 0) pour bloquer les horaires hors weekend
              elsif !(ta <= 16 and pa <= ta + 3) and !(ta >= 23 and pa >= ta - 5) and !((ta >= 18 and ta <= 20) and (pa >= ta -3 and pa <= ta + 5)) and !((ta == 21 or ta == 22) and pa >= 17) and !(ta == 17 and pa <= 21)
                # Vérifier l'écart d'âge entre le joueur et la moyenne d'âge de l'équipe
              elsif user.lang_p != lang
                # Vérifier que le joueur parle la même langue
              else
                @users_list_p << user
              end
            else
              @users_list_p << user
            end
          elsif !account.s_role.blank? and account.s_role.include? @role
            if @m_count > 0
              if @count_snd >= @max_snd
                # Vérifier si il n'y a pas déjà trop de seconds rôles dans l'équipe
              elsif !user.teamings.where(team_id: @team.id).empty?
                # Vérifier si le joueur n'a pas déjà fait partie de l'équipe
              elsif @team.members.count < 3 && user.teamings.where(active:true).present?
                # Retire les joueurs déjà en préteam si l'équipe ne contient pas plus de la moitier des joueurs requis
              elsif account_rank_gap?(@team_min, account) or account_rank_gap?(@team_max, account)
                # Vérifier si l'écart de niveau n'est pas trop important avec le premier et/ou le dernier joueur de l'équipe
              elsif (@we == false && (@end - @start < 2))
                # Vérifier si il y a au moins 2 heures en commun
              elsif !(ta <= 16 and pa <= ta + 3) and !(ta >= 23 and pa >= ta - 5) and !((ta >= 18 and ta <= 20) and (pa >= ta -3 and pa <= ta + 5)) and !((ta == 21 or ta == 22) and pa >= 17) and !(ta == 17 and pa <= 21)
                # Vérifier l'écart d'âge entre le joueur et la moyenne d'âge de l'équipesss
              elsif user.lang_p != lang
                # Vérifier que le joueur parle la même langue
              else
                @users_list_s << user
              end
            else
              @users_list_s << user
            end
          end
        end
      end
    else
      @users_list_p = User.searching.order(:date_search)
    end

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def tofit
    num_role = params[:num_role].to_i
    if @team.players[num_role] == 1
      @team.players[num_role] = 0
    elsif @team.players[num_role] == 0
      @team.players[num_role] = 1
    end
    if @team.save
      respond_to do |format|
        format.html { redirect_to @team, notice: "Demande de remplacement envoyée."}
        format.js
      end
    end
  end

  def remplacement
    @joueurs = @team.members
    @remplacants = @joueurs.where(state:1)
    @joueurs.each do |joueur|
      # Valide le changement d'état des remplacants uniquement.
      if joueur.state == 1
        joueur.state = 2
        joueur.save
        if joueur.team_applications.present?
          joueur.team_applications.destroy_all
        end
        Planning.find_or_create_by(user_id: joueur.id, team_id: @team.id)
        History.create(date: Time.now, team: @team, teaming: joueur.teamings.where(active:true).first, action:"member-join")
        Notification.create(recepteur: joueur, emetteur: current_user, category: "team", action: "placement", notifiable: @team)
        NotificationsMailer.remplacement(joueur, "remplacant", nil).deliver_now
        check_achievements(joueur,"teams")
      elsif joueur.state == 2
        Notification.create(recepteur: joueur, emetteur: current_user, category: "team", action: "remplacement", notifiable: @team)
        NotificationsMailer.remplacement(joueur, "membre", @remplacants).deliver_now
      end
    end
    respond_to do |format|
        format.html { redirect_to @team, notice: 'Remplacement validé avec succès.'}
        format.js
    end
  end

  def start
    # Valide le changement d'état de tous joueurs ayant un teaming actif avec l'équipe.
    @joueurs = User.joins(:teamings).where(:teamings => { team_id: @team.id, active: true })
    @joueurs.each do |joueur|
      joueur.state = 2
      joueur.save
      if joueur.team_applications.present?
        joueur.team_applications.destroy_all
      end
      if joueur.pending_invitations.present?
        joueur.pending_invitations.destroy_all
      end
      Planning.create(user_id: joueur.id, team_id: @team.id)
      Notification.create(recepteur: joueur, emetteur: current_user, category: "team", action: "placement", notifiable: @team)
      NotificationsMailer.start(joueur).deliver
      check_achievements(joueur,"teams")
    end
    Teaming.create(team: @team, active: true)
    History.create(date: Time.now, team: @team, action:"creation")
    @team.start_date = Time.now.to_s
    if @team.save
      respond_to do |format|
        format.html { redirect_to team_path, notice: "Equipe lancée avec succès !" }
        format.js
      end
    end

  end

  def dissolution
    Team.transaction do
      @user = User.find(params[:user])
      @teaming = Teaming.where(user_id: @user.id, team_id: @team.id, active: true).first
      if @team.users.count <= 3
        @team.members.where(state:2).each do |player|
          player.update_attribute(:state, 0)
        end
        @team.destroy!
      else
        @reason = params[dissolution_modal_team_path][:reason] unless params[dissolution_modal_team_path].nil?
        if !@reason.nil?
          @teaming.reason = @reason
          @teaming.save!
          History.create(date: Time.now, team: @team, teaming: @teaming, action:"member-leave")
        end
        # Action déclanchée soit par le recruteur, soit par l'un des 3 derniers joueurs d'une équipe demandant à la quitter.
        dissolution_process(@team)
      end # end of first if loop
      if can? :manage, @team
        respond_to do |format|
          format.html { redirect_to teams_path, notice: "Dissolution de l'équipe réussie." }
          format.js
        end
      else
        respond_to do |format|
          format.html { redirect_to dashboard_path, notice: "Départ et dissolution de l'équipe." }
          format.js
        end
      end # end of respond_to loop
    end # end of transaction
  end

  def tabs_refresh
    @champions = Champion.where(game_id: @team.game_id).pluck(:name)
    respond_to do |format|
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def team_params
      params.require(:team).permit(:name, :discord, :game_id, :roles)
    end

    def check_privileges!
      if !user_signed_in?
        redirect_to "/login", alert: 'Vous n\'avez pas accès à ce contenu.'
      end
    end

    def add_user_process(team, user, role, num_role)
      @team = team
      @user = user
      # Ancienne condition : if Teaming.where(:user_id => @user.id).where(:team_id => @team.id).where(:active => true).empty?
      # Nouvelle : Si le joueur est déjà en précompo et que le recruteur le place ailleurs alors faire le ménage dans la team précédente
      if @user.teamings.where(active:true).present?
        @user.teamings.where(active:true).each do |teaming|
          team = teaming.team
          team.u_count -= 1
          team.players[teaming.num_role] = 0
          team.save!
          teaming.destroy!
        end
      end

      if @team.team_applications.where(num_role: num_role).present?
        @team.team_applications.where(num_role: num_role).destroy_all
      end

      @teaming = Teaming.find_or_create_by(user_id: @user.id, team_id: @team.id)
      @teaming.role = role.downcase
      @teaming.num_role = num_role
      @teaming.active = true
      @teaming.save!

      # num_role = @team.roles.index(role)
      if !num_role.nil?
        @team.players[num_role] = 2
      end

      if @user.pending_invitations.exists?
        @user.pending_invitations.destroy_all
      end

      @team.u_count += 1
      @team.save!
    end

    def dissolution_process(team)
      Team.transaction do
        @team = team
        @teamings = Teaming.joins(:user).where(team_id: @team.id, active: true)
        @teamings.each do |teaming|
          teaming.active = false
          teaming.end_date = Time.now.to_s
          if teaming.reason == nil
            teaming.reason = 0
          end
          teaming.save!
          @player = teaming.user
          if @player.state == 2
            @player.update_attribute(:state, 0)
            Notification.create(recepteur: @player, emetteur: current_user, category: "team", action: "dissolution", notifiable: @team)
          end
        end
        @team.players.map { |p| p = 1 }

        History.create(date: Time.now, team: @team, action:"dissolution")
        @team.u_count = 0
        @team.end_date = Time.now.to_s
        @team.votes.destroy_all
        @team.save!
      end
    end
end
