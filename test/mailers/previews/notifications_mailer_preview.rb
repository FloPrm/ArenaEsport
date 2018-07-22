# Preview all emails at http://localhost:3000/rails/mailers/notifications_mailer
class NotificationsMailerPreview < ActionMailer::Preview

  def welcome
    @user = User.find(1)
    NotificationsMailer.welcome(@user)
  end

  def start
    @user = User.find(2397)
    NotificationsMailer.start(@user)
  end

  def remplacement
    @user = User.find(2397)
    NotificationsMailer.remplacement(@user, "membre", [User.find(2328)])
  end

  def team_invite
    @invitation = Invitation.find(2893)
    NotificationsMailer.team_invite(@invitation)
  end

  def new_mentor
    @mentor = Mentor.first
    NotificationsMailer.new_mentor(@mentor)
  end

  def mentorat_ask
    @mentorat = Mentorat.find(58)
    NotificationsMailer.mentorat_ask(@mentorat)
  end

  def mentorat_claim
    @user = User.find(88)
    NotificationsMailer.mentorat_claim(@user, "solo")
  end

  def mentorat_seance
    @seance = Seance.find(74)
    @user = User.find(1286)
    NotificationsMailer.mentorat_seance(@seance, @user, "solo")
  end

  def facture_premium
    @subscription = Subscription.last
    NotificationsMailer.facture_premium(@subscription)
  end

  def parrain_premium
    @user = User.first
    @subscription = Subscription.last
    @type = "upgrade"
    @duration = 31
    NotificationsMailer.parrain_premium(@user, @subscription, @type, @duration)
  end

  def application_new
    @user = User.find(456)
    @application = @user.team_applications.last
    NotificationsMailer.application_new(@user, @application)
  end

  def application_validated
    @user = User.find(35)
    NotificationsMailer.application_validated(@user)
  end
end
