module SubscriptionPlansHelper
  def renewal?
    if user_signed_in? && (current_user.active_subscription.present? && current_user.active_subscription.subscription_plan_id == @subscription_plan.id)
      return true
    else
      return false
    end
  end
end
