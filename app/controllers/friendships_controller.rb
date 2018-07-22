class FriendshipsController < ApplicationController
  before_action :set_asker
  before_action :set_asked, except: [:create]
  before_action :set_team

  skip_before_action :verify_authenticity_token

  def index
    # 28/03 - fix rollbar item 26
    redirect_to dashboard_path, alert: "Une erreur s'est produite dans votre liste de notifications. Veuillez contacter un administrateur."
  end

  def create
    if params[:friendship].nil?
      @asked = User.find(params[:asked])
    else
      @account = GameAccount.where("replace(lower(name), ' ', '') LIKE ?", params[:friendship][:friend].downcase.gsub(/\s+/, '')).first
      unless @account.nil?
        @asked = @account.user
      else
        @asked = nil
      end
    end
    @user = @asked

    unless @asked.nil?
      unless Friendship.where(user_id: @asker.id, friend_id: @asked.id, status: 2).exists?
        unless Friendship.where(user_id: @asker.id, friend_id: @asked.id, status: 0).exists?
          unless Friendship.where(user_id: @asker.id, friend_id: @asked.id, status: 1).exists?
            Friendship.create(user_id: @asker.id, friend_id: @asked.id, status: 0)
            Friendship.create(user_id: @asked.id, friend_id: @asker.id, status: 1)
            Notification.create(recepteur: @asked, emetteur: @asker, category:"friendship", action:"request", notifiable: @asker)
          else
            @friendship1 = Friendship.where(user_id: @asker.id, friend_id: @asked.id).first
            @friendship2 = Friendship.where(user_id: @asked.id, friend_id: @asker.id).first
            @friendship1.update_attribute(:status, 2)
            @friendship2.update_attribute(:status, 2)
            Notification.create(recepteur: @asked, emetteur: @asker, category:"friendship", action:"accept", notifiable: @asker)
          end
          if params[:team].nil?
            respond_to do |format|
              format.html { redirect_to @asked, notice: "Demande d'ami envoyée." }
              format.js { flash[:friend] = "Demande d'ami envoyée." }
            end
          else
            respond_to do |format|
              format.html { redirect_to @team, notice: "Demande d'ami envoyée." }
              format.js { flash[:friend] = "Demande d'ami envoyée." }
            end
          end
        else
          respond_to do |format|
            format.js { flash[:friend] = "Demande en attente de validation." }
          end
        end
      else
        respond_to do |format|
          format.js { flash[:friend] = "Le joueur est déjà dans votre liste d'amis." }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to dashboard_path, alert: "Nom incorrect ou le joueur n'est pas inscrit sur Arena." }
        format.js { flash[:friend] = "Nom incorrect ou joueur inconnu." }
      end
    end
  end

  def accept
    @friendship1 = Friendship.where(user_id: @asker.id, friend_id: @asked.id).first
    @friendship2 = Friendship.where(user_id: @asked.id, friend_id: @asker.id).first
    @friendship1.update_attribute(:status, 2)
    @friendship2.update_attribute(:status, 2)
    Notification.create(recepteur: @asker, emetteur: @asked, category:"friendship", action:"accept", notifiable: @asked)
    check_achievements(@asker,"friendships")
    check_achievements(@asker,"friendships")
    if params[:team].nil?
      respond_to do |format|
        format.html { redirect_to @asker, notice: "Demande d'ami acceptée." }
        format.js
      end
    else
      redirect_to @team, notice: "Demande d'ami acceptée."
      return
    end
  end

  def decline
    Friendship.where(user_id: @asker.id, friend_id: @asked.id).first.destroy
    Friendship.where(user_id: @asked.id, friend_id: @asker.id).first.destroy
    if params[:team].nil?
      respond_to do |format|
        format.html { redirect_to @asker, notice: "Demande d'ami refusée." }
        format.js
      end
    else
      redirect_to @team, notice: "Demande d'ami refusée."
      return
    end
  end

  def remove
    Friendship.where(user_id: @asker.id, friend_id: @asked.id).first.destroy
    Friendship.where(user_id: @asked.id, friend_id: @asker.id).first.destroy unless Friendship.where(user: @asked.id, friend: @asker.id).first.status == 3
    if params[:team].nil?
      respond_to do |format|
        format.html { redirect_to @asked, notice: "L'utilisateur a été retiré de votre liste d'amis." }
        format.js
      end
    else
      respond_to do |format|
        format.html { redirect_to @team, notice: "L'utilisateur a été retiré de votre liste d'amis." }
        format.js
      end
    end
  end

  def block
    if @asker.friends.include?(@asked)
      @friendship1 = Friendship.where(user_id: @asker.id, friend_id: @asked.id).first
      @friendship2 = Friendship.where(user_id: @asked.id, friend_id: @asker.id).first.destroy unless Friendship.where(user: @asked.id, friend: @asker.id).first.status == 3
      @friendship1.update_attribute(:status, 3)
    else
      Friendship.create(user_id: @asker.id, friend_id: @asked.id, status: 3)
    end
    if params[:team].nil?
      respond_to do |format|
        format.html { redirect_to @asked, notice: "L'utilisateur a été bloqué." }
        format.js
      end
    else
      redirect_to @team, notice: "L'utilisateur a été bloqué."
      return
    end
  end

  def unblock
    Friendship.where(user_id: @asker.id, friend_id: @asked.id).first.destroy
    if params[:team].nil?
      respond_to do |format|
        format.html { redirect_to @asked, notice: "L'utilisateur a été débloqué." }
        format.js
      end
    else
      redirect_to @team, notice: "L'utilisateur a été débloqué."
      return
    end
  end

  private

  def set_team
    @team = Team.find(params[:team]) unless params[:team].nil?
  end

  def set_asker
    @asker = User.find(params[:asker])
  end

  def set_asked
    @asked = User.find(params[:asked])
    @user = @asked
  end
end
