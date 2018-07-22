class MentoratsController < ApplicationController
  before_action :check_privileges!
  before_action :set_mentorat, only: [:show, :edit, :update, :claim, :stop]

  def index
    if current_user.mentor.present?
      # Joueurs
      @search = Mentorat.joins(:game_account).where(:game_accounts => { game_id: current_user.account.game_id }).search(params[:q])
      @mentorats = @search.result.includes(:game_account)
      @pending = @mentorats.where(status:0).where(teacher_id: current_user.mentor.id)
      # Teams
      @search_t = Mentorat.joins(:team).where(:teams => { game_id: current_user.account.game_id }).search(params[:q])
      @mentorats_t = @search_t.result
      @pending_t = @mentorats_t.where(status:0).where(teacher_id: current_user.mentor.id)
      # Mentor
      @actifs = User.joins(:mentorat).where(:mentorats => {mentor_id: current_user.mentor.id, status: 1})
      @actifs_t = Team.joins(:mentorat).where(:mentorats => {mentor_id: current_user.mentor.id, status: 1})
      @students = (User.joins(:mentorat).where(:mentorats => {mentor_id: current_user.mentor.id, status: 1}) + User.joins(:seances).where(:seances => {mentor_id: current_user.mentor.id, status: 1})).uniq
      # Important : @seances ne doit pas inclure les séance dont le "status" est 0 = en attente de validation
      @seances = current_user.mentor.seances
      @hours = current_user.mentor.seances.where(status:1).pluck(:duration).inject(:+)/60 unless !current_user.mentor.seances.where(status:1).present?
    else
      redirect_to dashboard_path, alert: 'Vous devez être Mentor pour pouvoir accéder à cette page.'
    end
  end

  def show
    if @mentorat.mentor.present?
      if current_user == @mentorat.user
        @user = @mentorat.mentor.user
        @mentor = @mentorat.mentor unless @mentorat.mentor.nil?
        @account = @mentor.game_account
      else
        @user = @mentorat.user
        @account = @mentorat.game_account
        @mentor = @mentorat.mentor unless @mentorat.mentor.nil?
      end
    else
      @user = @mentorat.user
      @account = @mentorat.game_account
      @mentor = nil
    end
    @seances = @mentorat.seances
  end

  def mentorat_preview
    @mentorat = Mentorat.find(params[:id])
    if @mentorat.game_account_id.present?
      @user = @mentorat.user
      @account = @mentorat.game_account
      @target = @mentorat
    else
      @team = @mentorat.team
      @target = @team
    end
    respond_to do |format|
      format.html { redirect_to @target }
      format.js
    end
  end

  def new
    @mentorat = Mentorat.new
    @mentor = Mentor.find(params[:teacher])
    @account = @mentor.game_account unless params[:teacher].nil?
    @problem_length = Mentorat.validators_on( :problem ).first.options[:maximum]
    # 16/03/17 prévention bug
    if current_user.game_accounts.empty?
      redirect_to mentors_path, alert: "Vous devez avoir un compte de jeu pour demander du mentorat"
    elsif !(current_user.can? :update, User)
      redirect_to mentors_path, alert: t('alerts.banned_action')
    end
  end

  def create
    @mentorat = Mentorat.new(params_mentorat)

    @user = current_user
    @user.skype = params[:user][:skype]
    @user.discord = params[:user][:discord]

    @account = GameAccount.find_by_name(params[:mentorat][:teacher])
    @mentorat.teacher = @account.mentor
    @mentorat.last_swap = Time.now

    unless params[:team].present?
      @mentorat.game_account = @user.account
    else
      @mentorat.team_id = params[:team]
    end
    @mentorat.status = 0
    if @mentorat.save
      @user.save
      unless @mentorat.team.present?
        @action = "demande"
        @redirect = @mentorat
      else
        @action = "demande-team"
        @redirect = @mentorat.team
      end
      Notification.create(emetteur: current_user, recepteur: @account.user, category:"mentorat", action:@action, notifiable: @mentorat)
      NotificationsMailer.mentorat_ask(@mentorat).deliver_now
      redirect_to @redirect, notice: "Demande de Mentorat envoyée avec succès."
    else
      redirect_to @account.mentor, alert: "Une erreur s'est produite lors de l'enregistrement de votre demande."
    end
  end

  def edit
    @problem_length = Mentorat.validators_on( :problem ).first.options[:maximum]
  end

  def update
    @mentorat.update(params_mentorat)
    @user = current_user
    @user.skype = params[:user][:skype]
    @user.discord = params[:user][:discord]
    @mentorat.save
      @user.save
      redirect_to dashboard_path, notice: "Votre demande de Mentorat a été mise à jour."
  end

  def change_teacher
    if current_user.can? :update, User
      unless params[:team].present?
        @mentorat = current_user.mentorat
        @action = "demande"
      else
        @mentorat = current_user.team.mentorat
        @action = "demande-team"
      end
      if @mentorat.status == 2
        @mentorat.status = 0
      end
      @teacher = Mentor.find(params[:teacher])
      @mentorat.teacher = @teacher
      @mentorat.last_swap = Time.now
        @mentorat.save
        Notification.where('created_at > ?', 24.hours.ago).where(emetteur: current_user, category:"mentorat", action:@action).destroy_all
        Notification.create(emetteur: current_user, recepteur: @teacher.user, category:"mentorat", action:@action, notifiable: @mentorat)
        NotificationsMailer.mentorat_ask(@mentorat).deliver_now
        redirect_to @teacher, notice: "Votre demande de Mentorat été mise à jour. Mentor souhaité actualisé."
    else
      redirect_to mentors_path, alert: t('alerts.banned_action')
    end
  end

  def claim
    @mentorat.status = 1
    @mentorat.mentor_id = current_user.mentor.id
    @mentorat.save
    unless @mentorat.team.present?
      @target = @mentorat
      @notice = "L'élève vous a été attribué avec succès."
      Notification.create(emetteur: current_user, recepteur: @mentorat.user, category:"mentorat", action:"claim", notifiable: @mentorat)
      NotificationsMailer.mentorat_claim(@mentorat.user, "solo").deliver_now
    else
      @target = @mentorat.team
      @notice = "L'équipe vous a été attribuée avec succès."
      @mentorat.team.members.where(state:2).each do |member|
        Notification.create(emetteur: current_user, recepteur: member, category:"mentorat", action:"claim-team", notifiable: @mentorat.team)
        NotificationsMailer.mentorat_claim(member, "team").deliver_now
      end
    end
    redirect_to @target, notice: @notice
  end

  def stop
    if @mentorat.team.present?
      @team = @mentorat.team
    end
    if current_user != @mentorat.mentor.user
      Notification.create(recepteur: @mentorat.mentor.user, emetteur: current_user, category:"mentorat", action:"student-stop", notifiable: @mentorat)
      if @team.nil?
        @target = @mentorat
      else
        @target = @team
      end
    elsif current_user == @mentorat.mentor.user
      if Seance.where(mentorat: @mentorat, mentor: @mentorat.mentor).where('updated_at > ?', 2.weeks.ago).present?
        if @team.nil?
          Notification.create(recepteur: @mentorat.user, emetteur: current_user, category:"mentorat", action:"mentor-stop", notifiable: @mentorat.mentor)
        else
          @team.members.where(state:2).each do |player|
            Notification.create(recepteur: player, emetteur: current_user, category:"mentorat", action:"mentor-stop-team", notifiable: @mentorat.mentor)
          end
        end
      else
        if @team.nil?
          Notification.create(recepteur: @mentorat.user, emetteur: current_user, category:"mentorat", action:"mentor-stop-empty", notifiable: @mentorat.mentor)
        else
          @team.members.where(state:2).each do |player|
            Notification.create(recepteur: player, emetteur: current_user, category:"mentorat", action:"mentor-stop-empty-team", notifiable: @mentorat.mentor)
          end
        end
      end
      if @team.nil?
        @target = @mentorat
      else
        @target = mentorats_url
      end
    end
    if Seance.where(mentorat_id: @mentorat.id, mentor_id: @mentorat.mentor_id).where('updated_at > ?', 2.weeks.ago).present?
      if @mentorat.team.nil?
        Feedback.create(mentorat_id: @mentorat.id, mentor_id: @mentorat.mentor_id)
      elsif @mentorat.team.present? && current_user != @mentorat.mentor.user
        Feedback.create(user_id: current_user.id, mentor_id: @mentorat.mentor_id)
      elsif @mentorat.team.present? && current_user == @mentorat.mentor.user
        if @team.teamings.where(active:true, captain:true).present?
          @user = @team.teamings.where(active:true, captain:true).first.user
        elsif @team.members.where(state:2,role:"captain_p").present?
          @user = @team.members.where(state:2,role:"captain_p").first
        end
        Feedback.create(user_id: @user.id, mentor_id: @mentorat.mentor_id)
      end
    end
    @mentorat.status = 2
    @mentorat.mentor_id = nil
    @mentorat.teacher = nil
    @mentorat.hours = 0
    if @mentorat.save
      redirect_to @target, notice: "Fin du suivi. La demande de mentorat a été désactivée jusqu'à la prochaine réservation."
    else
      redirect_to @target, alert: "Une erreur est survenue."
    end
  end

  private

  def set_mentorat
    @mentorat = Mentorat.find(params[:id])
  end

  def params_mentorat
    params.require(:mentorat).permit(:hours, :problem)
  end

end
