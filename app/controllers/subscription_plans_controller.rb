class SubscriptionPlansController < ApplicationController
  before_action :check_privileges!, except: [:show, :select_duration]
  before_action :set_subscription_plan, only: [:show, :edit, :update, :destroy, :select_duration, :payment_result]
  include SubscriptionPlansHelper

  def index
    authorize! :manage, :all
    @subscription_plans = SubscriptionPlan.all
  end

  def show
    @price_ttc = @subscription_plan.price
    @tva = @price_ttc * 20 / 100
    @price_ht = @price_ttc - @tva
    @gem_price = (@price_ttc.ceil * 150).to_i
    unless user_signed_in? && (current_user.active_subscription.present? && current_user.active_subscription.subscription_plan_id == @subscription_plan.id)
      @label = t('subscriptions.subscribe')
      @subscription = Subscription.new
    else
      @label = t('subscriptions.renew')
      @subscription = current_user.active_subscription
    end
  end

  def select_duration
    @duration = params[:duration].to_i
    @price = @subscription_plan.price * @duration
    if @duration == 3
      @price_ttc = @price - (@price * 5 / 100)
    elsif @duration == 6
      @price_ttc = @price - (@price * 10 / 100)
    elsif @duration == 12
      @price_ttc = (@price - (@subscription_plan.price * 2)).ceil
    else
      @price_ttc = @price
    end
    @tva = @price_ttc * 20 / 100
    @price_ht = @price_ttc - @tva
    @gem_price = (@price_ttc.ceil * 150).to_i
    respond_to do |format|
      format.js
    end
  end

  def new
    authorize! :manage, :all
    @subscription_plan = SubscriptionPlan.new
  end

  def create
    authorize! :manage, :all
    @subscription_plan = SubscriptionPlan.create(subscription_plan_params)
    redirect_to @subscription_plan, notice: "Plan de souscription créé."
  end

  def edit
    authorize! :manage, :all
  end

  def update
    authorize! :manage, :all
    @subscription_plan.update(subscription_plan_params)
    redirect_to @subscription_plan, notice: "Plan de souscription mis à jour."
  end

  def destroy
    authorize! :manage, :all
    @subscription_plan.destroy
    redirect_to subscription_plans, notice: "Plan de souscription supprimé."
  end

  def informations
    @user = current_user
    @plan = SubscriptionPlan.find(params[:id])
    @subscription = Subscription.find(params[:subscription])
    if @subscription.renewal_price.nil?
      @price = @subscription.price.to_f
      @gem_price = (@subscription.price.ceil * 150).to_i
      @date1 = Time.now.to_date
      @date2 = @subscription.end_date
    else
      @price = @subscription.renewal_price.to_f
      @gem_price = (@subscription.renewal_price.ceil * 150).to_i
      @date1 = @subscription.end_date
      @date2 = (@subscription.end_date + @subscription.renewal_duration.months).to_date
    end
    @duration = (@date2.year * 12 + @date2.month) - (@date1.year * 12 + @date1.month) unless @subscription.end_date.nil?
  end

  def payment
    SubscriptionPlan.transaction do
      @user = current_user
      @user.first_name = params[:user][:first_name]
      @user.last_name = params[:user][:last_name]
      @user.address = params[:user][:address]
      @user.save!

      @subscription = Subscription.find(params[:subscription])
      if params[:payment_method] == "gems"
        if @subscription.renewal_price.nil?
          @gem_price = (@subscription.price.ceil * 150).to_i
          @type = "subscription"
        else
          @gem_price = (@subscription.renewal_price.ceil * 150).to_i
          @type = "renewal"
        end
        unless @gem_price > @user.wallet.balance
          wallet_manager(@user, nil, @gem_price, "debit", "premium")
          if @type == "subscription"
            # Si c'est la souscription, passer le prix de euros en gems
            @subscription.price = @gem_price
          elsif @type == "renewal" && @subscription.price > 700
            @subscription.end_date += @subscription.renewal_duration.months
            # Si la souscription était en gems, incrémenter le prix, sinon laisser en euros.
            @subscription.price += @gem_price
          end
          @subscription.active = true
          @subscription.payment_method = "gems"
          @user.role = @subscription.subscription_plan.role
          unless @subscription.renewal_price.nil?
            @subscription.renewal_price = nil
            @subscription.renewal_duration = nil
          end
          @user.save!
          @subscription.save!
          if @type == "subscription" && !@user.parrain.nil?
            parrain_premium(@user, @subscription)
          end
          redirect_to payment_result_subscription_plan_path(@subscription.subscription_plan, response: @type)
          # redirect_to dashboard_path, notice:"Abonnement à la formule #{@subscription.subscription_plan.title} réussi ! Merci de ta confiance ツ"
        else
          redirect_to informations_subscription_plan_path(params[:id], duration: params[:duration], price: @subscription.price), alert: "Solde insuffisant, vous devez approvisionner votre compte en gems."
        end
      elsif params[:payment_method] == "paypal"
        @subscription.update_attribute(:payment_method, "paypal")
        @success = payment_response_subscription_plan_url(response:"success")
        @failure = payment_response_subscription_plan_url(response:"failure")
        paypal_options = {
          no_shipping: true, # if you want to disable shipping information
          allow_note: false, # if you want to disable notes
          pay_on_paypal: true # if you don't plan on showing your own confirmation step
        }
        if Rails.env.development?
          Paypal.sandbox!
          request = paypal_development_request
        elsif Rails.env.production?
          request = paypal_production_request
        end
        payment_request = Paypal::Payment::Request.new(
          :currency_code => :EUR,   # if nil, PayPal use USD as default
          :description   => "Formule premium #{@subscription.subscription_plan.title} ", # item description
          :quantity      => 1,      # item quantity
          :amount        => @subscription.renewal_price.nil? ? @subscription.price.to_f : @subscription.renewal_price.to_f,   # item value
        )
        response = request.setup(
          payment_request,
          @success,
          @failure,
        )
        redirect_to response.redirect_uri
      else
        redirect_to informations_subscription_plan_path(params[:id], duration: params[:duration], price: @subscription.price), alert: "Méthode de paiement non reconnue."
      end
    end
  end

  def payment_response
    @user = current_user
    if params[:response] == "success"
      @subscription = @user.subscriptions.last
      @subscription.active = true
      @subscription.payment_method == "paypal"
      @subscription.token = params[:token]
      @subscription.payer_id = params[:PayerID]
      paypal_checkout(@subscription)
      NotificationsMailer.facture_premium(@subscription).deliver_now

      unless @subscription.renewal_price.nil?
        @duration = @subscription.renewal_duration.to_i
        @subscription.end_date += @duration.months
        @subscription.price += @subscription.renewal_price
        @subscription.renewal_price = nil
        @subscription.renewal_duration = nil
        @type = "renewal"
      else
        @type = "subscription"
      end

      if @subscription.save
        @user.update_attribute(:role, @subscription.subscription_plan.role)
      end
      if @type == "subscription" && !@user.parrain.nil?
        parrain_premium(@user, @subscription)
      end
      redirect_to payment_result_subscription_plan_path(@subscription.subscription_plan, response: @type)
    else
      redirect_to payment_result_subscription_plan_path(@subscription.subscription_plan, response: "failure")
    end
  end

  def payment_result
  end

  def restricted_content
    respond_to do |format|
      format.html { redirect_to pricing_path, alert: "Vous devez être premium pour pouvoir accéder à ce contenu." }
      format.js
    end
  end

  private

  def paypal_checkout(subscription)
    @subscription = subscription
    if Rails.env.development?
      Paypal.sandbox!
      request = paypal_development_request
    elsif Rails.env.production?
      request = paypal_production_request
    end
    payment_request = Paypal::Payment::Request.new(
      :currency_code => :EUR,   # if nil, PayPal use USD as default
      :description   => "Formule premium #{@subscription.subscription_plan.title} ", # item description
      :quantity      => 1,      # item quantity
      :amount        => @subscription.price.to_f,   # item value
    )
    response = request.checkout!(
      @subscription.token,
      @subscription.payer_id,
      payment_request
    )
  end

  def paypal_development_request
    Paypal::Express::Request.new(
      username: "paypal-facilitator_api1.arena-esport.com",
      password: "VBKSCRCLNVXTSJN6",
      signature: "AFcWxV21C7fd0v3bYYYRCpSSRl31AJZ3NaMtj1snevpQOr1sOHtA40zp"
    )
  end

  def paypal_production_request
    Paypal::Express::Request.new(
      username: "paypal_api1.arena-esport.com",
      password: "D96LG7KD9MTUVBDM",
      signature: "AFcWxV21C7fd0v3bYYYRCpSSRl31As.Al3.NfzC9FxDn03iQzXQnKpfv"
    )
  end

  def subscription_plan_params
    params.require(:subscription_plan).permit(:title, :content, :price, :role, :duration, :active)
  end

  def set_subscription_plan
    @subscription_plan = SubscriptionPlan.find(params[:id])
  end

  def parrain_premium(user, subscription)
    @user = user
    @parrain = User.find(@user.parrain)
    @subscription = subscription
    if @parrain.created_at <= 1.months.ago
      if @parrain.active_subscription.present?
        @active = @parrain.active_subscription
        if @active.subscription_plan_id == @subscription.subscription_plan_id
          @end_date = @active.end_date.to_date += 31.days
          @type = "extend"
          @duration = 31
        elsif @active.subscription_plan_id == 1 && @subscription.subscription_plan_id == 2
          @end_date = @active.end_date.to_date += 31.days
          @active.subscription_plan_id = 2
          @type = "upgrade"
          @duration = 31
        else
          @end_date = @active.end_date += 21.days
          @type = "extend"
          @duration = 21
        end
        @active.end_date = @end_date
        @active.save!
      else
        Subscription.create(user:@parrain, subscription_plan:@subscription.subscription_plan, price:0, payment_method:"parrainage", end_date:@subscription.end_date, active:true)
        @type = "subscription"
        @duration = 31
      end
      @parrain.role = @subscription.subscription_plan.role
      @parrain.save!
      NotificationsMailer.parrain_premium(@parrain, @subscription, @type, @duration).deliver_now
    end
  end

  def slack_event(user, plan, payment,duration)
    uri = URI('https://hooks.slack.com/services/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')

    text = "L'utilisateur "+user.user_name+" s'est inscrit à la formule "+plan+" pour une durée de "+ duration+" en payant par "+payment+"."


    slack_message.body = {
      channel: "#formules",
      username:"Magallie travestie",
      icon_emoji: "jerrybg",
      text:text
    }.to_json
  end
end
