class SeancesController < ApplicationController
  before_action :check_privileges!
  before_action :set_seance, only: [:show, :edit, :update, :validate, :destroy]

  def show
    respond_to do |format|
      format.js
    end
  end

  def new
    @seance = Seance.new
    @content_length = Seance.validators_on( :content ).first.options[:maximum]
    respond_to do |format|
      format.js
    end
  end

  def create
    @mentorat = Mentorat.find(params[:mentorat])
    @seance = Seance.new(seance_params)
    @seance.mentor = current_user.mentor
    @seance.mentorat = @mentorat
    @seance.status = 0
    if @mentorat.team.nil?
      @target = @mentorat
    else
      @target = @mentorat.team
    end

    if @seance.save
      if @seance.date > Time.now
        if @mentorat.team.nil?
          Notification.create(emetteur: current_user, recepteur: @seance.mentorat.user, category:"seance", action:"new", notifiable: @seance.mentorat)
          NotificationsMailer.mentorat_seance(@seance, @seance.mentorat.user, "solo").deliver_now
        else
          @mentorat.team.members.where(state:2).each do |player|
            Notification.create(emetteur: current_user, recepteur: player, category:"seance", action:"new", notifiable: @target)
            NotificationsMailer.mentorat_seance(@seance, player, "team").deliver_now
          end
        end
      end
      redirect_to @target, notice: "Séance créée avec succès."
    else
      redirect_to @target, alert: "Une erreur s'est produite."
    end
  end

  def edit
    @content_length = Seance.validators_on( :content ).first.options[:maximum]
    @advice_length = Seance.validators_on( :advice ).first.options[:maximum]
    respond_to do |format|
      format.js
    end
  end

  def update
    if @seance.mentorat.team.present?
      @team = @seance.mentorat.team
    end
    @seances = @seance.mentor.seances
    @seance.update(seance_params)
    respond_to do |format|
      format.js
    end
  end

  def validate
    if @seance.mentorat.team.present?
      @team = @seance.mentorat.team
    end
    @seances = @seance.mentorat.seances
    if params[:validation] == "1"
      @seance.status = 1
      if @team.nil?
        @seance.mmr = @seance.mentorat.user.account.mmr
      end
    elsif params[:validation] == "2"
      @seance.status = 2
      if @team.nil?
        @seance.mmr = @seance.mentorat.user.account.mmr
      end
    end
    @mentor = @seance.mentor
    unless @mentor.seances.where('status > ?', 0)
      @hours = @mentor.seances.where(status:1).pluck(:duration).inject(:+)/60
      if @hours >= 200
        @mentor.certification = 3 unless @mentor.certification == 3
      elsif @hours >= 100
        @mentor.certification = 2 unless @mentor.certification == 2
      elsif @hours >= 50
        @mentor.certification = 1 unless @mentor.certification == 1
      end
    end
    if @team.nil?
      check_achievements(@seance.mentorat.user,"mentorats")
    end
    check_achievements(@seance.mentor.user,"mentors")
    @seance.save
    @mentor.save
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @mentorat = @seance.mentorat
    @seances = @seance.mentor.seances
    unless @mentorat.team.present?
      @target = @mentorat
    else
      @team = @mentorat.team
      @target = @team
    end
    @seance.destroy
    respond_to do |format|
      format.html { redirect_to @target, notice: "La séance a bien été supprimée." }
      format.js
    end
  end

  private

  def seance_params
    params.require(:seance).permit(:title, :date, :hour, :duration, :content, :advice)
  end

  def set_seance
    @seance = Seance.find(params[:id])
  end

end
