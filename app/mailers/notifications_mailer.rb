class NotificationsMailer < ApplicationMailer

  def welcome(user)
    @user = user
    @email = @user.email
    set_locale(@email)
    #unless Rails.env.development?
      mail(to: @email, subject: "Bienvenue sur Arena Esport !")
    #end
  end

  def start(user)
    @user = user
    @game_account = @user.account
    @team = @user.team
    @game = @team.game
    @email = @user.email
    set_locale(@email)
    unless check_unsubscribe(@user)
      mail(to: @email, subject: "Arena Esport - Proposition d'équipe")
    end
  end

  def remplacement(user, status, remplacants)
    @user = user
    @game_account = @user.account
    @team = @user.team
    @game = @team.game
    @status = status
    @remplacants = remplacants
    @email = @user.email
    set_locale(@email)
    unless check_unsubscribe(@user)
      if @status == "membre"
        mail(to: @email, subject: "Arena Esport - Remplacement de joueurs")
      elsif @status == "remplacant"
        mail(to: @email, subject: "Arena Esport - Proposition d'équipe")
      end
    end
  end

  def team_invite(invitation)
    @invitation = invitation
    @sender = @invitation.sender
    @receiver = @invitation.receiver
    @team = @invitation.team
    @content = @invitation.content
    @email = @receiver.email
    set_locale(@email)
    unless check_unsubscribe(@receiver)
      mail(to: @email, subject: "Arena Esport - Invitation en équipe")
    end
  end

  def new_mentor(mentor)
    @mentor = mentor
    @email = @mentor.user.email
    set_locale(@email)
    unless check_unsubscribe(@mentor.user)
      mail(to: @email, subject: "Le Mentorat sur Arena Esport en quelques points")
    end
  end

  def mentorat_ask(mentorat)
    @mentorat = mentorat
    if @mentorat.team.nil?
      @student = @mentorat.account
    else
      @student = @mentorat.team
    end
    @mentor = @mentorat.teacher.account
    @email = @mentor.user.email
    set_locale(@email)
    unless check_unsubscribe(@mentor.user)
      mail(to: @email, subject: "Arena Esport - Nouvelle demande de Mentorat")
    end
  end

  def mentorat_claim(user, type)
    @type = type
    if type == "solo"
      @mentorat = user.mentorat
      @student = @mentorat.account
      @subject = "Arena Esport - Un Mentor a pris en charge ta demande"
    elsif type == "team"
      @mentorat = user.team.mentorat
      @student = user.account
      @subject = "Arena Esport - Un Mentor a pris en charge l'équipe"
    end
    @mentor = @mentorat.mentor.account
    @email = @student.user.email
    set_locale(@email)
    unless check_unsubscribe(@student.user)
      mail(to: @email, subject: @subject)
    end
  end

  def mentorat_seance(seance, user, type)
    @seance = seance
    @student = user.account
    @type = type
    if type == "solo"
      @subject = "Arena Esport - Ta prochaine séance de Mentorat"
    elsif type == "team"
      @subject = "Arena Esport - Prochaine séance de Mentorat d'équipe"
    end
    @mentor = @seance.mentor.account
    @email = @student.user.email
    set_locale(@email)
    unless check_unsubscribe(@student.user)
      mail(to: @email, subject: @subject)
    end
  end

  def facture_premium(subscription)
    @subscription = subscription
    if @subscription.renewal_price.nil?
      @price_ttc = @subscription.price.to_f
    else
      @price_ttc = @subscription.renewal_price.to_f
    end
    @tva = @price_ttc * 20 / 100
    @price_ht = @price_ttc - @tva
    if @subscription.renewal_price.nil?
      @date1 = @subscription.created_at
      @date2 = @subscription.end_date
    else
      @date1 = @subscription.end_date
      @date2 = (@subscription.end_date + @subscription.renewal_duration.months).to_date
    end
    @duration = (@date2.year * 12 + @date2.month) - (@date1.year * 12 + @date1.month) unless @subscription.end_date.nil?

    @user = @subscription.user
    @email = @user.email
    set_locale(@email)
    unless Rails.env.development?
      mail(to: @email, subject: "Arena Esport - Facture achat premium")
    end
  end

  def parrain_premium(user, subscription, type, duration)
    @subscription = subscription
    @user = user
    @filleul = @subscription.user
    @type = type
    @duration = duration
    @email = @user.email
    set_locale(@email)
    unless Rails.env.development?
      mail(to: @email, subject: "Arena Esport - Extension de l'abonnement Premium !")
    end
  end

  def application_new(user, application)
    @user = user
    @application = application
    @email = @user.email
    set_locale(@email)
    unless check_unsubscribe(@user)
      mail(to: @email, subject: "Arena Esport - Un joueur souhaite rejoindre l'équipe")
    end
  end

  def application_validated(user)
    @user = user
    @team = @user.team
    @email = @user.email
    set_locale(@email)
    unless check_unsubscribe(@user)
      mail(to: @email, subject: "Arena Esport - Candidature acceptée !")
    end
  end

  private

  def check_unsubscribe(user)
    @user = user
    if @user.unsubscribe or Rails.env.development?
      return true
    else
      return false
    end
  end

  def set_locale(email)
    @user = User.find_by_email(email)
    I18n.locale = @user.language[0..1] || I18n.default_locale
  end

end
