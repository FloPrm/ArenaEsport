class InvitationsController < ApplicationController
  include InvitationsHelper

  skip_before_action :verify_authenticity_token

  def new
    @user = current_user
    @receiver = User.find(params[:receiver])
    @team = current_user.teamings.where(active:true).first.team
    respond_to do |format|
      format.js
    end
  end

  def create
    Invitation.transaction do
      if params[:type] == "team" or params[:type] == "premium"
        @team = current_user.team
        if params[:friend].present? && params[:role].present?
          if can? :manage, Champion
            @account = GameAccount.where("replace(lower(name), ' ', '') LIKE ?", params[:friend].downcase.gsub(/\s+/, '')).first
          else
            @account = current_user.friends_accounts.where("replace(lower(name), ' ', '') LIKE ?", params[:friend].downcase.gsub(/\s+/, '')).first
          end
          unless @account.nil?
            if @account.user.pending_invitations.where(team: @team, num_role: params[:num_role].to_i).present?
              respond_to do |format|
                format.js { flash[:invitation] = "Invitation en attente." }
              end
            elsif @account.user.state == 2
              respond_to do |format|
                format.js { flash[:invitation] = "Le joueur fait partie d'une équipe." }
              end
            else
              @invitation = Invitation.new(sender_id: current_user.id, receiver_id: @account.user_id)
              @invitation.action = "team"
              @invitation.team = @team
              @invitation.role = params[:role]
              @invitation.num_role = params[:num_role].to_i
              Notification.create(recepteur_id: @account.user_id, emetteur_id: current_user.id, category:"invitation", action:"team")
              @invitation.save!
              respond_to do |format|
                format.html { redirect_to dashboard_path, notice: "Invitation envoyée." }
                format.js { flash[:invitation] = "Invitation envoyée." }
              end
            end
          else
            if can? :manage, Champion
              respond_to do |format|
                format.html { redirect_to dashboard_path, notice: "Joueur introuvable, verifiez l'ortographe." }
                format.js { flash[:invitation] = "Joueur introuvable, verifiez l'ortographe." }
              end
            else
              respond_to do |format|
                format.html { redirect_to dashboard_path, notice: "Le joueur n'est pas dans votre liste d'amis." }
                format.js { flash[:invitation] = "Le joueur n'est pas dans votre liste d'amis." }
              end
            end
          end
        else
          @invitation = Invitation.new(sender_id: current_user.id, receiver_id: params[:receiver])
          @invitation.action = "team"
          @invitation.team = @team
          if params[:type] == "premium"
            @invitation.role = params[:role]
            @invitation.num_role = params[:num_role]
            @invitation.content = params[new_invitation_path][:content]
          end
          Notification.create(recepteur_id: params[:receiver], emetteur_id: current_user.id, category:"invitation", action:"team")
          if @invitation.save!
            # fix rollbar item 39
            unless @invitation.receiver.nil?
              NotificationsMailer.team_invite(@invitation).deliver
            end
            respond_to do |format|
              format.js { flash[:invitation] = "Invitation envoyée." }
            end
          else
            respond_to do |format|
              format.js { flash[:invitation] = "Une erreur s'est produite." }
            end
          end
        end
      elsif params[:type] == "premade"
        if params[:friend].present?
          if can? :manage, Champion
            @account = GameAccount.where("replace(lower(name), ' ', '') LIKE ?", params[:friend].downcase.gsub(/\s+/, '')).first
          else
            @account = current_user.friends_accounts.where("replace(lower(name), ' ', '') LIKE ?", params[:friend].downcase.gsub(/\s+/, '')).first
          end
          unless @account.nil?
            if @account.user.state == 2
              respond_to do |format|
                format.js { flash[:invitation] = "Le joueur fait partie d'une équipe." }
              end
            elsif @account.user.team_applications.present?
              respond_to do |format|
                format.js { flash[:invitation] = "Le joueur a des candidatures en attente." }
              end
            elsif current_user.team_applications.present?
              respond_to do |format|
                format.js { flash[:invitation] = "Vous avez des candidatures en attentes." }
              end
            elsif @account.user.premade.present?
              respond_to do |format|
                format.js { flash[:invitation] = "Le joueur fait partie d'une premade." }
              end
            elsif @account.tier == "unranked" && @account.flex_tier == "unranked"
              respond_to do |format|
                format.js { flash[:invitation] = "Le joueur doit être classé pour entrer en recherche." }
              end
            elsif @account.game != current_user.account.game
              respond_to do |format|
                format.js { flash[:invitation] = "Le joueur est sur un jeu différent." }
              end
            elsif current_user.invitations.where(receiver_id: @account.user_id, action:"premade").present?
              respond_to do |format|
                format.js { flash[:invitation] = "Invitation en attente de validation." }
              end
            else
              unless account_rank_gap?(@account, current_user.account)
                @invitation = Invitation.new(sender_id: current_user.id, receiver_id: @account.user_id)
                @invitation.action = "premade"
                Notification.create(recepteur_id: @account.user_id, emetteur_id: current_user.id, category:"invitation", action:"premade")
                @invitation.save!
                respond_to do |format|
                  format.html { redirect_to dashboard_path, notice: "Invitation envoyée." }
                  format.js { flash[:invitation] = "Invitation envoyée." }
                end
              else
                respond_to do |format|
                  format.js { flash[:invitation] = "Écart de niveau trop important." }
                end
              end
            end
          else
            if can? :manage, Champion
              respond_to do |format|
                format.html { redirect_to dashboard_path, notice: "Joueur introuvable, verifiez l'ortographe." }
                format.js { flash[:invitation] = "Joueur introuvable, verifiez l'ortographe." }
              end
            else
              respond_to do |format|
                format.html { redirect_to dashboard_path, notice: "Le joueur n'est pas dans votre liste d'amis." }
                format.js { flash[:invitation] = "Le joueur n'est pas dans votre liste d'amis." }
              end
            end
          end
        end # params[:friend].present? loop end
      end # params[:type] loop end
    end # transaction end
  end

  def accept
    Invitation.transaction do
      @invitation = Invitation.find(params[:id])
      @user = @invitation.receiver
      if @invitation.action == "team"
        # Réalise les actions Add_User & Remplacement du TeamsController
        @team = @invitation.team
          # Si le joueur était en precompo alors il en est retiré avant d'être placé dans la nouvelle équipe.
          if @user.teamings.where(active:true).where.not(team_id: @team.id).present?
            @user.teamings.where(active:true).where.not(team_id: @team.id).each do |teaming|
              team = teaming.team
              team.u_count -= 1
              team.players[teaming.num_role] = 0
              team.save!
              teaming.destroy!
            end
          end
          if @team.invitations.where(num_role:@invitation.num_role).where.not(receiver:@user).present?
            @team.invitations.where(num_role:@invitation.num_role).where.not(receiver:@user).each do |invitation|
              Notification.where(recepteur_id:@invitation.user_id, category:"invitation", action:"team").last.destroy
              invitation.destroy
            end
          end

          @team.users << User.find(@user.id)
          @team.u_count += 1
          @team.players[@invitation.num_role] = 2

          @teaming = Teaming.where(user_id: @user.id, team_id: @team.id, active: nil).first
          @teaming.role = @team.roles[@invitation.num_role]
          @teaming.num_role = @invitation.num_role
          @teaming.active = true
          @joueurs = @team.members
          (@joueurs - [@user]).each do |joueur|
            Notification.create(recepteur: joueur, emetteur: @user, category: "team", action: "invité", notifiable: @team)
          end
          Planning.create(user_id: @user.id, team_id: @team.id)
          @user.state = 2
          # Supprime les autres invitations en cours dans le cas ou il y en a plusieurs pour un même rôle
          (Invitation.where(team: @team, num_role: @invitation.num_role) - [@invitation]).each do |invitation|
            invitation.destroy!
          end
          if @teaming.save!
            History.create(date: Time.now, team: @team, teaming: @user.teamings.where(active:true).first, action:"member-join")
            @team.save!
            @user.save!
            check_achievements(@user,"teams")
            redirect_to @team, notice: "Bienvenue dans l'équipe !"
          end

      elsif @invitation.action == "premade"
        unless @invitation.sender.premade.present? && @invitation.sender.state == 2
          if @invitation.sender.premade.present?
            @premade = @invitation.sender.premade
            if @premade.user1.nil?
              @premade.user1 = @invitation.receiver.account
            elsif @premade.user2.nil?
              @premade.user2 = @invitation.receiver.account
            elsif @premade.user3.nil?
              @premade.user3 = @invitation.receiver.account
            else
              redirect_to dashboard_path, alert: "L'invitation n'est plus valide car la premade est complète."
            end
            @premade.save!
          else
            @premade = Premade.create(user1: @invitation.sender.account, user2: @invitation.receiver.account)
          end
        else
          redirect_to dashboard_path, alert: "L'invitation n'est plus valide car le joueur est en équipe."
        end
        unless @premade.nil?
          # Envoi la notification sauf si l'invitation n'est plus valide
          if @premade.users.include?(@invitation.receiver.account)
            Notification.create(recepteur_id: @invitation.sender_id, emetteur_id: @invitation.receiver_id, category:"premade", action:"accept")
            if @invitation.sender.state == 1
              @invitation.receiver.state = 1
              @invitation.receiver.date_search = Time.now.to_s
              @invitation.receiver.save!
            end
          end
          unless @premade.users.count == 3
            redirect_to dashboard_path, notice: "Invitation acceptée."
          end
        end
      end
      @invitation.destroy!
    end
  end

  def decline
    @invitation = Invitation.find(params[:id])
    @team = Team.find(params[:team]) unless params[:team].nil?
    @invitation.destroy
    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "Invitation refusée." }
      format.js
    end
  end

end
