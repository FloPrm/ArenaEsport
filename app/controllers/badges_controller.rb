class BadgesController < ApplicationController
  before_action :set_badge, only: [:edit, :update]

  def index
    @badges = Badge.all
  end

  def new
    @badge = Badge.new
    @vectors = Dir.glob("app/assets/images/badges/*.svg")
    respond_to do |format|
      format.js
    end
  end

  def create
    @badge = Badge.create(badge_params)
    @badges = Badge.all
    respond_to do |format|
      format.html { redirect_to badges_path }
      format.js
    end
  end

  def edit
    @vectors = Dir.glob("app/assets/images/badges/*.svg")
    respond_to do |format|
      format.js
    end
  end

  def update
    @badge.update(badge_params)
    respond_to do |format|
      format.html { redirect_to badges_path }
      format.js
    end
  end

  private

  def set_badge
    @badge = Badge.find(params[:id])
  end

  def badge_params
    params.require(:badge).permit(:name, :description, :icon, :icon_color, :icon_style, :bg, :bg_color)
  end

end
