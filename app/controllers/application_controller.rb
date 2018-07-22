class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include ApplicationHelper
  before_action :set_locale
  before_action :set_mailer_options
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_notifications, if: :user_signed_in?
  before_action :new_friendship, if: :user_signed_in?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to dashboard_url, :alert => "Vous n'êtes pas autorisé à accéder à cette page."
  end

  rescue_from Paypal::Exception::APIError do |e|
    redirect_to dashboard_url, :alert => "#{e.message} #{e.response} #{e.response.details}"
    # => 'PayPal API Error'
   # => Paypal::Exception::APIError::Response
   # => Array of Paypal::Exception::APIError::Response::Detail. This includes error details for each payment request.
  end

  #si première connexion, on en est à l'inscription, donc redirection sur la deuxième étape
	def after_sign_in_path_for(resource_or_scope)
    #16/03/17 fix rollbar #7
    if resource.nil?
      second_step_path
    elsif resource.sign_in_count == 1
      second_step_path
    else
      dashboard_path
    end
	end

  def set_locale
    if user_signed_in? && current_user.language.present?
      I18n.locale = current_user.language[0..1] || I18n.default_locale
    else
      I18n.locale = params[:locale] || I18n.default_locale
    end
  end

  def default_url_options
    { :locale => I18n.locale }
  end

  def set_mailer_options
    ActionMailer::Base.default_url_options[:locale] = I18n.locale
  end

  def new_friendship
    @friendship = Friendship.new
  end

  def set_notifications
    if user_signed_in?
    @notifications = Notification.where(recepteur: current_user)
    end
  end

  def wallet_manager(user1, user2, amount, action, category)
    @user1 = user1.wallet
    ActiveRecord::Base.transaction do
      if action == "credit" && !user1.nil?
        credit(user1, amount)
        @history1 = WalletHistory.new(wallet: @user1, action: action, category: category, amount: amount)
      elsif action == "debit" && !user1.nil?
        debit(user1, amount)
        @history1 = WalletHistory.new(wallet: @user1, action: action, category: category, amount: amount)
      elsif action == "transfer" && (!user1.nil? && !user2.nil?)
        @user2 = user2.wallet
        transfer(user1, user2, amount)
        @history1 = WalletHistory.new(wallet: @user1, action: "transfer-debit", category: category, amount: amount)
        @history2 = WalletHistory.new(wallet: @user2, action: "transfer-credit", category: category, amount: amount)
        @history2.save!
      end
      @history1.save!
    end
  end

  def check_subscription(user)
    ActiveRecord::Base.transaction do
      @user = user
      if @user.active_subscription.present?
        @subscription = @user.active_subscription
        if @subscription.end_date.present? && @subscription.end_date.to_date < Time.now.to_date
          @user.role = "standard"
          @subscription.active = false
          @subscription.save!
          @user.save!
        end
      end
    end
  end

  def leave_premade(user, label)
    @user = user
    @premade = @user.premade
    @premades = @user.premades
    if @premade.users.count == 3
      if @premade.user1 == @user.account
        @premade.user1 = nil
      elsif @premade.user2 == @user.account
        @premade.user2 = nil
      elsif @premade.user3 == @user.account
        @premade.user3 = nil
      end
      @premade.save
    elsif @premade.users.count == 2
      @premade.destroy
    end
    @premades.each do |premade|
      if label == "leave-search"
        Notification.create(emetteur: @user, recepteur: premade.user, category:"premade", action:"leave-search", notifiable: @user)
      elsif label == "leave-team"
        Notification.create(emetteur: @user, recepteur: premade.user, category:"premade", action:"leave-team", notifiable: @user)
      end
    end
  end

  protected

    def credit(user, amount)
      @wallet = user.wallet
      @wallet.balance += amount
      puts "\n Credited from #{amount} gems. \n"
      @wallet.save!
    end

    def debit(user, amount)
      @wallet = user.wallet
      @wallet.balance -= amount
      puts "\n Debited from #{amount} gems. \n"
      @wallet.save!
    end

    def transfer(sender, receiver, amount)
      @sender = sender.wallet
      @receiver = receiver.wallet
      @sender.balance -= amount
      @receiver.balance += amount
      puts "\n Transfer of #{amount} gems. \n"
      @sender.save!
      @receiver.save!
    end

    def check_achievements(user, category)
      @user = user
      @achievements = Achievement.where(category: category)
      @achievements.each do |achievement|
        if eval("User.find(#{@user.id}).#{achievement.condition}") && !@user.achievements.include?(achievement)
          puts "\n\n True: shit happens \n\n"
          @user.achievements << achievement
          wallet_manager(@user, nil, achievement.reward, "credit", "achievement")
        end
      end
    end

    #définition des paramètres acceptés par devise lors de l'inscription / mise à jour d'un utilisateur
    def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :user_name, :email, :birth_date, :country, :language, :password, :password_confirmation])
        devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :user_name, :email, :password, :current_password, :password_confirmation, :avatar, :role, :lang_p, :address])
    end

    def check_privileges!
      if !user_signed_in?
        redirect_to "/login"
      end
    end
end
