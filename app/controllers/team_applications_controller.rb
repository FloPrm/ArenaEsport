class TeamApplicationsController < ApplicationController
  before_action :check_privileges!
  before_action :set_team_application, only: [:reject, :answer, :destroy]

  def index
    authorize! :manage, Article
    @team_applications = TeamApplication.all.paginate(:page => params[:page])
  end

  def recruitment_center
    if current_user.account.nil?
      redirect_to dashboard_path, alert: "Vous devez avoir un compte de jeu actif pour pouvoir accéder à cette page."
    elsif !(current_user.can? :update, User)
      redirect_to dashboard_path, alert: t('alerts.banned_content')
    else
      @game = current_user.account.game
      unless current_user.state == 2
        @teams = Team.where(game_id: @game.id, end_date: nil).where('u_count < ?', @game.nb_players).order('updated_at')
        @premiums = []
        @teams.joins(:users).where(:users => {role: "captain_p"}).each do |team|
          if team.players.include?(0)
            @premiums << team
          end
        end
        @tofits = @teams.where.not(start_date: nil) - @premiums
        @precompos = @teams.where(start_date: nil)
      else
        redirect_to dashboard_path, alert: "Le contenu que vous essayer d'accéder est réservé aux joueurs en recherche d'équipe."
      end
    end
  end

  def new
    @team_application = TeamApplication.new
    @team = Team.find(params[:team])
    @members = @team.members
    # AGE
    @ages = @members.pluck(:birth_date).map{|d| d.find_age}
    @average = @ages.inject(0.0) { |sum, el| sum + el } / @ages.size
    # HORAIRE
    @week_start = (@members.pluck(:week_start) + [current_user.week_start]).sort.last
    @week_end =  (@members.pluck(:week_end) + [current_user.week_end]).sort.first
    @we_start = (@members.pluck(:we_start) + [current_user.we_start]).sort.last
    @we_end = (@members.pluck(:we_end) + [current_user.we_end]).sort.first
    @week = @week_end - @week_start
    @we = @we_end - @we_start
    # TRYHARD
    @gameplays = @team.accounts.pluck(:gameplay).reject(&:nil?)
    @gameplay = @gameplays.inject(0.0) { |sum, el| sum + el } / @gameplays.size
    respond_to do |format|
      format.html { redirect_to recruitment_center_path, alert: "Problème de chargement de la fenêtre de candidature." }
      format.js
    end
  end

  def create
    TeamApplication.transaction do
      unless current_user.premade.present?
        @team_application = TeamApplication.new(team_application_params)
        @team_application.user_id = current_user.id
        @team_application.team_id = params[:team]
        @team_application.num_role = params[:num_role].to_i
        @user = @team_application.user
        @account = @user.account
        @team = @team_application.team
        @team_application.role = @team.roles[@team_application.num_role]
        unless @account.p_role == @team_application.role or @account.s_role.include?(@team_application.role)
          @account.s_role << @team_application.role
          @account.save
        end
        if @team_application.save!
          @joueurs = @team.members.where(state:2)
          @joueurs.each do |joueur|
            Notification.create(recepteur: joueur, emetteur: current_user, category: "team_application", action: "new", notifiable: @team) unless joueur.nil?
            NotificationsMailer.application_new(joueur, @team_application).deliver_now unless joueur.nil?
          end
          redirect_to recruitment_center_path, notice: "Votre candidature a bien été envoyée."
        else
          redirect_to recruitment_center_path, alert: "Une erreur s'est produite au moment de l'envoi de votre candidature."
        end
      else
        redirect_to recruitment_center_path, alert: "Vous devez être seul pour pouvoir postuler dans une équipe."
      end
    end
  end

  def reject
    @reasons = {
      "#{t 'team_applications.r1'}" => 1,
      "#{t 'team_applications.r2'}" => 2,
      "#{t 'team_applications.r3', character: current_user.account.game.character_name.pluralize}" => 3,
      "#{t 'team_applications.r4'}" => 4,
      "#{t 'team_applications.r5'}" => 5
    }
    respond_to do |format|
      format.js
    end
  end

  def answer
    TeamApplication.transaction do
      @user = @team_application.user
      @team = @team_application.team
      if params[:answer] == "true"
        unless @team.members.count == @team.game.nb_players
          if @user.state < 2 && @user.teamings.where(active:true).present?
            teaming = @user.teamings.where(active:true).first
            team = teaming.team
            team.plannings.where(user: @user).destroy_all
            team.players[teaming.num_role] = 0
            team.u_count -= 1
            team.save!
            teaming.destroy!
          end
          @teaming = Teaming.create(user: @user, team: @team, active: true, role: @team_application.role, num_role: @team_application.num_role)
          Planning.create(user: @user, team: @team)
          @team.players[@team_application.num_role] = 2
          @team.u_count += 1
          unless @team.start_date.nil?
            @user.update_attribute(:state, 2)
            History.create(date: Time.now, team: @team, teaming: @teaming, action:"member-join")
            Notification.create(recepteur: @user, emetteur: current_user, category: "team_application", action: "validated", notifiable: @team)
          end
          if @team.team_applications.where(num_role: @team_application.num_role).where.not(user: @user).present?
            @team.team_applications.where(num_role: @team_application.num_role).where.not(user: @user).each do |application|
              Notification.create(recepteur: application.user, emetteur: current_user, category: "team_application", action: "not-selected")
              application.destroy!
            end
          end
          if @user.team_applications.where.not(team: @team).present?
            @user.team_applications.where.not(team: @team).destroy_all
          end
          unless @team.start_date.nil?
            NotificationsMailer.application_validated(@user).deliver_now
          end
          @team.save!
          @team_application.destroy!
          redirect_to @team, notice: "Le joueur a été ajouté à l'équipe."
        else
          redirect_to @team, alert: "L'équipe est complète."
        end
      elsif params[:answer] == "false"
        Notification.create(recepteur: @user, emetteur: current_user, category: "team_application", action: "rejected", content: params[:reason])
        @team_application.destroy!
        respond_to do |format|
          format.html { redirect_to @team, notice: "La candidature a été rejetée." }
          format.js
        end
      end
    end
  end

  def destroy
    if @team_application.destroy
      if can? :manage, :all
        redirect_to team_applications_path, notice: "Candidature supprimée."
      else
        redirect_to recruitment_center_path, notice: "Candidature supprimée."
      end
    else
      redirect_to recruitment_center_path, alert: "Une erreur s'est produite."
    end
  end

  private

  def set_team_application
    @team_application = TeamApplication.find(params[:id])
  end

  def team_application_params
    params.require(:team_application).permit(:content)
  end
end
