class SubscriptionsController < ApplicationController
  before_action :check_privileges!
  before_action :set_subscription, only: [:state, :destroy]
  before_action :set_subscriptions, only: [:index, :state, :destroy]

  def index
    authorize! :manage, :all
    respond_to do |format|
      format.html
      format.js
    end
  end

  def manager
    @subscription = current_user.active_subscription
    @subscriptions = current_user.subscriptions.where.not(active:nil)
  end

  def create
    @user = current_user
    @plan = SubscriptionPlan.find(params[:plan])
    @end_date = (Time.now.tomorrow + params[:duration].to_i.months).to_date unless params[:duration].nil?
    @price = params[:price].to_f.round(2)
    @subscription = Subscription.find_or_create_by(user: @user, subscription_plan: @plan, end_date: @end_date, price: @price, active: nil)
    redirect_to informations_subscription_plan_path(@plan, subscription: @subscription.id)
  end

  def renewal
    @user = current_user
    @subscription = @user.active_subscription
    @subscription.renewal_price = params[:price].to_f.round(2)
    @subscription.renewal_duration = params[:duration].to_i
    @subscription.save
    redirect_to informations_subscription_plan_path(@subscription.subscription_plan, subscription: @subscription.id)
  end

  def state
    Subscription.transaction do
      @user = @subscription.user
      unless @subscription.end_date < Time.now
        unless @user.can? :manage, :all
          if @subscription.active == true
            @subscription.active = false
            @user.role = "standard"
          elsif @subscription.active == false
            @subscription.active = true
            @user.role = @subscription.subscription_plan.role
          else
            @subscription.active = true
            @user.role = @subscription.subscription_plan.role
          end
          @subscription.save!
          @user.save!
          respond_to do |format|
            format.html { redirect_to subscriptions_path, notice: "Etat de l'abonnement mis a jour." }
            format.js
          end
        end
      else
        redirect_to subscriptions_path, alert: "Cet abonnement est expiré."
      end
    end
  end

  def destroy
    Subscription.transaction do
      @user = @subscription.user
      if @user.role == @subscription.subscription_plan.role
        @user.role = "standard"
        @user.save!
      end
      @subscription.destroy!
      respond_to do |format|
        format.html { redirect_to subscriptions_path, notice:"Abonnement supprimé avec succès" }
        format.js
      end
    end
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end

  def set_subscriptions
    @search = Subscription.joins(:account).search(params[:q])
    @subscriptions = @search.result.paginate(:page => params[:page])
  end
end
