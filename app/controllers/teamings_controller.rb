class TeamingsController < ApplicationController

  def index
    authorize! :manage, Article
    @search = Teaming.joins(:team).where.not(:teams => { start_date: nil }).search(params[:q])
    @teamings = @search.result.paginate(:page => params[:page])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def swap
    @asker = Teaming.find(params[:asker])
    @asked = Teaming.find(params[:asked]) unless params[:asked].nil?
    @team = @asker.team

    unless params[:asked].nil? && !params[:role].nil?

      unless !@asker.swap.nil?
        @asker.swap = params[:asked]
        @asker.save
        Notification.create(recepteur: @asked.user, emetteur: current_user, category:"swap", action:"asked-swap", notifiable: @team)
        Notification.create(recepteur: current_user, emetteur: current_user, category:"swap", action:"asker-swap", notifiable: @team)
      end

      unless params[:answer].nil?
        if params[:answer] == "true"
          @role1 = @asker.role
          @num_role1 = @asker.num_role
          @role2 = @asked.role
          @num_role2 = @asked.num_role

          @asked.role = @role1
          @asked.num_role = @num_role1
          @asker.role = @role2
          @asker.num_role = @num_role2
          @asker.swap = nil
          @asked.save
          @asker.save
          Notification.create(recepteur: @asker.user, emetteur: current_user, category:"swap", action:"swap-yes", notifiable: @team)
        else
          @asker.swap = nil
          @asker.save
          Notification.create(recepteur: @asker.user, emetteur: current_user, category:"swap", action:"swap-no", notifiable: @team)
        end
      end

    else
      @role1 = @asker.role
      @num_role1 = @asker.num_role
      @role2 = params[:role]
      @num_role2 = params[:num_role].to_i

      num_role = @num_role1
      if !num_role.nil?
        @team.players[num_role] = 1
      end

      num_role = @num_role2
      if !num_role.nil?
        @team.players[num_role] = 2
      end

      @asker.role = @role2
      @asker.num_role = @num_role2
      @asker.save
      @team.save
    end

    respond_to do |format|
      format.html { redirect_to @team }
      format.js
    end
  end

  def swaper
    @team = Team.find(params[:team])
    num_role = params[:num_role].to_i
    if params[:direction] == "up"
      target = num_role - 1
    elsif params[:direction] == "down"
      target = num_role + 1
    end
    @teaming1 = @team.teamings.where(active:true, num_role: num_role).first
    @role1 = @team.roles[num_role]
    @teaming2 = @team.teamings.where(active:true, num_role: target).first
    @role2 = @team.roles[target]

    @teaming1.num_role = target
    @teaming1.role = @role2
    @team.players[target] = 2
    if @teaming2.present?
      @team.players[num_role] = 2
      @teaming2.num_role = num_role
      @teaming2.role = @role1
      @teaming2.save
    else
      @team.players[num_role] = 1
    end
    if @team.invitations.where(num_role: target).exists?
      @team.invitations.where(num_role: target).each do |invitation|
        Notification.where(recepteur_id: invitation.receiver_id, category:"invitation", action:"team").first.destroy
        invitation.destroy
      end
    end
    @teaming1.save
    @team.save
    respond_to do |format|
      format.html { redirect_to @team, notice: "Changement de rôle opéré avec succès"}
      format.js
    end
  end

  def swap_captain
    @captain = Teaming.where(user_id: params[:captain], active: true).first
    @user = Teaming.where(user_id: params[:user], active: true).first
    @team = @captain.team
    @joueurs = User.joins(:teamings).where(:teamings => {team_id: @team.id, active: true})

    if @captain.captain == true
      @captain.captain = false
      @user.captain = true
      @captain.save
      @user.save
      (@joueurs - [@user.user]).each do |joueur|
        Notification.create(recepteur: joueur, emetteur: current_user, category:"swap", action:"captain-changed", notifiable: @team)
      end
      Notification.create(recepteur: @user.user, emetteur: current_user, category:"swap", action:"captain-given", notifiable: @team)
    end
    respond_to do |format|
      format.html { redirect_to @team, notice: "Changement de capitaine opéré avec succès." }
    end
  end

  def advices_validation
    @teaming = current_user.teamings.where(active:true).first
    @teaming.update_attribute(:advices, true)
    respond_to do |format|
      format.html
      format.js
    end
  end

end
