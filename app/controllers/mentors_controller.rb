class MentorsController < ApplicationController
  before_action :check_privileges!
  before_action :set_mentor, only: [:show, :edit, :update, :dashboard]
  before_action :set_lenght, only: [:new, :edit]

  def index
    if current_user.language == "french"
      ordering = ["french", "english"]
    else
      ordering = ["english", "french"]
    end
    unless current_user.account.nil?
      @game = current_user.account.game
      @search = Mentor.joins(:game_account).where(:game_accounts => { game_id: @game.id }).where(active:true).search(params[:q])
      @mentors = @search.result.includes(:game_account).paginate(:page => params[:page])
    else
      redirect_to second_step_path, alert: "Vous devez lier un compte de jeu pour pouvoir accéder à cette page."
    end
  end

  def show
    @user = @mentor.user
    @account = @mentor.game_account
    @feedbacks = @mentor.feedbacks.where('average > ?', 0)

    @students = (User.joins(:mentorat).where(:mentorats => {mentor_id: @mentor.id, status: 1}) + User.joins(:seances).where(:seances => {mentor_id: @mentor.id, status: 1})).uniq
    # Important : @seances ne doit pas inclure les séance dont le "status" est 0 = en attente de validation
    @seances = @mentor.seances.where('status > ?', 0)
    @validated = @mentor.seances.where(status:1)
    @hours = @mentor.seances.where(status:1).pluck(:duration).inject(:+)/60 unless @validated.empty?
  end

  # Devenir Mentor
  def new
    if current_user.can? :update, User
      @mentor = Mentor.new
    else
      redirect_to dashboard_path, alert: t('alerts.banned_action')
    end
  end

  def create
    @mentor = Mentor.new(mentor_params)
    @mentor.suivi = params[:suivi]
    @mentor.game_account = current_user.account
    @mentor.active = true
    if @mentor.save
      NotificationsMailer.new_mentor(@mentor).deliver
      redirect_to @mentor, notice: "Profil de Mentor créé avec succès."
    else
      render :new, alert: "Une erreur s'est produite, veuillez réessayer."
    end
  end

  def edit
  end

  def update
    @mentor.update(mentor_params)
    @mentor.suivi = params[:suivi]
    if @mentor.save
      redirect_to @mentor, notice: "Le profil de Mentor a été mis à jour."
    else
      render :edit
    end
  end

  def dashboard
    @mentorats = @mentor.mentorats
  end

  private

  def set_mentor
    @mentor = Mentor.find(params[:id])
  end

  def mentor_params
    params.require(:mentor).permit(:about, :cours, :week_start, :week_end, :we_start, :we_end, :active, :certification)
  end

  def set_lenght
    @about_length = Mentor.validators_on( :about ).first.options[:maximum]
    @cours_length = Mentor.validators_on( :cours ).first.options[:maximum]
  end

end
