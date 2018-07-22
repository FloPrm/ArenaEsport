class PremadesController < ApplicationController
  
  skip_before_action :verify_authenticity_token

  def index
    @search = Premade.search(params[:q])
    @premades = @search.result
  end

  def leave
    @user = current_user
    @premade = @user.premade
    @user.premades.each do |premade|
      Notification.create(recepteur: premade.user, emetteur: @user, category:"premade", action:"leave")
    end
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
    redirect_to dashboard_path, notice: "Vous avez quitté la premade."
  end

  def kick
    @premade = Premade.find(params[:id])
    @friend = User.find(params[:friend])
    if @premade.users.count == 3
      if @premade.user1 == @friend.account
        @premade.user1 = nil
      elsif @premade.user2 == @friend.account
        @premade.user2 = nil
      elsif @premade.user3 == @friend.account
        @premade.user3 = nil
      end
      @premade.save
    elsif @premade.users.count == 2
      @premade.destroy
    end
    if can? :manage, :all
      redirect_to premades_path, notice: "Le joueur a été retiré de la premade."
    else
      redirect_to dashboard_path, notice: "Le joueur a été retiré de la premade."
    end
  end
end
