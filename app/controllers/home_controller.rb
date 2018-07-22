class HomeController < ApplicationController
require 'date'
#c'est ici que les pages non liées à un model sont créees

def index
=begin
    if user_signed_in?
      redirect_to dashboard_path and return
    end
=end
end

def profil_user_type
end

def contact
end

def about
end

def join_us
end

def our_partners
end

def our_streamers
end

def our_team
end

def pricing
end

def pantheon
end

def unsubscribe
  if params[:email].present?
    @user = User.find_by_email(params[:email].to_s)
    @user.unsubscribe = true
    @user.save
  end
end

def old_page
	redirect_to root_path
end

def admin_panel
	unless can? :manage, Article
		redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
	end

  @users = User.all
  @teams = Team.where.not(start_date: nil)
  @teamings = Teaming.joins(:user, :team).where.not(:teams => {start_date:nil})
end

def codename_fifty
end

def analytics
  unless can? :manage, Article
    redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
  end

  @start_date = Date.parse("2017-04-15")
  @end_date = Date.today
  @users = User.where('users.created_at BETWEEN ? AND ?', @start_date, @end_date)

  @teams = Team.where.not(start_date: nil).where('start_date BETWEEN ? AND ?', @start_date, @end_date)

  @lol_accounts = GameAccount.where(:game_id => 1).where.not(:p_role => nil)
  @ow_accounts = GameAccount.where(:game_id => 2)

  @age_min = User.maximum(:birth_date).find_age
  @age_max = User.minimum(:birth_date).find_age


  @insc_total = @users.count
  @insc_rech = @users.where(:state => 1).count
  @insc_team = @users.where(:state => 2).count
  @insc_off = @users.where(:state => 0).count
  @lol = @users.joins(:game_accounts).merge(GameAccount.where(:active => true, :game_id => 1))
  @lol_total = @lol.count
  @lol_rech = @lol.where(:state => 1).count
  @lol_team = @lol.where(:state => 2).count
  @lol_off = @lol.where(:state => 0).count
  @ow = @users.joins(:game_accounts).merge(GameAccount.where(:active => true, :game_id => 2))
  @ow_total = @ow.count
  @ow_rech = @ow.where(:state => 1).count
  @ow_team = @ow.where(:state => 2).count
  @ow_off = @ow.where(:state => 0).count

end

def analytics_search

  unless can? :manage, Article
    redirect_to root_path, alert: 'Vous n\'avez pas accès à ce contenu.'
  end

  #Date Picked
  if params[:start_date].blank?
    @start_date = Date.parse("2017-03-09")
  else
    @start_date = Date.parse(params[:start_date]).to_s
  end

  if params[:end_date].blank?
    @end_date = Date.today
  else
     @end_date = Date.parse(params[:end_date]).end_of_day.to_s
  end

  if params[:age_min].blank?
    @age_min = User.maximum(:birth_date).find_age
  else
    @age_min = params[:age_min]
  end
  @year_max = @age_min.to_i.years.ago

  if params[:age_max].blank?
    @age_max = User.minimum(:birth_date).find_age
  else
    @age_max = params[:age_max]
  end
  @year_min = @age_max.to_i.years.ago

  @users = User.where('users.created_at BETWEEN ? AND ? ', @start_date, @end_date)
  @users = @users.where('birth_date BETWEEN ? AND ? ', @year_min, @year_max)

  @teams = Team.where.not(start_date: nil).where('start_date > ?', @start_date)

  @lol_accounts = GameAccount.where(:game_id => 1)#.where.not(:p_role => nil)
  @ow_accounts = GameAccount.where(:game_id => 2)

  @insc_total = @users.count
  @insc_rech = @users.where(:state => 1).count
  @insc_team = @users.where(:state => 2).count
  @insc_off = @users.where(:state => 0).count
  @lol = @users.joins(:game_accounts).merge(GameAccount.where(:active => true, :game_id => 1))
  @lol_total = @lol.count
  @lol_rech = @lol.where(:state => 1).count
  @lol_team = @lol.where(:state => 2).count
  @lol_off = @lol.where(:state => 0).count
  @ow = @users.joins(:game_accounts).merge(GameAccount.where(:active => true, :game_id => 2))
  @ow_total = @ow.count
  @ow_rech = @ow.where(:state => 1).count
  @ow_team = @ow.where(:state => 2).count
  @ow_off = @ow.where(:state => 0).count

  respond_to do |format|
    format.js{}
  end
end


end
