class AchievementsController < ApplicationController
  before_action :set_achievement, only: [:edit, :update]

  def index
    @achievements = Achievement.all.paginate(:page => params[:page])
  end

  def new
    @achievement = Achievement.new
    @badges = Badge.where(achievement_id:nil)
    respond_to do |format|
      format.js
    end
  end

  def create
    @achievement = Achievement.new(achievement_params)
    @achievement.badge = Badge.find(params[:achievement][:badge]) unless params[:achievement][:badge].empty?
    @achievement.save
    @achievements = Achievement.all
    respond_to do |format|
      format.html { redirect_to achievements_path }
      format.js
    end
  end

  def edit
    @badges = ([@achievement.badge] + Badge.where(achievement_id:nil)).reject(&:nil?)
    respond_to do |format|
      format.js
    end
  end

  def update
    @achievement.update(achievement_params)
    @achievement.badge = Badge.find(params[:achievement][:badge]) unless params[:achievement][:badge].empty?
    @achievement.save
    respond_to do |format|
      format.html { redirect_to achievements_path }
      format.js
    end
  end

  def add_user
    @achievements = Achievement.all
    @account = GameAccount.where("replace(lower(name), ' ', '') LIKE ?", params[:user].downcase.gsub(/\s+/, '')).first
    unless @account.nil?
      @user = @account.user
      @wallet = @user.wallet
      @achievement = Achievement.find(params[:id])
      unless @user.achievements.include?(@achievement)
        @user.achievements << @achievement
        @wallet.balance += @achievement.reward
        @wallet.save
        respond_to do |format|
          format.js { flash[:achievement] = "Achievement accordé." }
        end
      else
        respond_to do |format|
          format.js { flash[:achievement] = "Le joueur possède déjà l'achievement." }
        end
      end
    else
      respond_to do |format|
        format.js { flash[:achievement] = "Joueur introuvable." }
      end
    end
  end

  private

  def set_achievement
    @achievement = Achievement.find(params[:id])
  end

  def achievement_params
    params.require(:achievement).permit(:name, :description, :reward, :condition, :category)
  end

end
