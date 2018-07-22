class VotesController < ApplicationController

  # GET /votes
  # GET /votes.json
  def index
    @votes = Vote.all
  end

  # GET /votes/1
  # GET /votes/1.json
  def show
  end

  def edit
  end

  def update
  end

  # GET /votes/new
  def new
    @vote = Vote.new
    @team = Team.find(params[:team])
    @joueurs = User.joins(:teamings).where(:teamings => {team_id: @team.id, active: true})
    @candidates = []
    @joueurs.each do |joueur|
      @candidates << joueur.game_accounts.where(active:true).first
    end
    respond_to do |format|
      format.html { redirect_to @team, alert: "Problème de chargement de la fenêtre de vote." }
      format.js
    end
  end

  # POST /votes
  # POST /votes.json
  def create
    @captain = User.find(params[:vote][:votable])
    @team = Team.find(@captain.teamings.where(active:true).first.team_id)
    @joueurs = User.joins(:teamings).where(:teamings => { team_id: @team.id, active: true })

    unless @team.votes.where(action:"élection", result: nil).exists?
      @vote = Vote.create(team_id: @team.id, votable: @captain, action:"élection", counter: 1, votes: 1, has_voted:Array.new(@team.game.nb_players, nil))
      @joueur = current_user.teamings.where(team_id: @team.id, active:true).first
      @vote.has_voted[@joueur.num_role] = true
      @vote.save

      @joueurs.each do |joueur|
        Notification.create(recepteur: joueur, emetteur: current_user, category:"vote", action:"élection", notifiable: @team)
      end
      respond_to do |format|
        format.html { redirect_to @team, notice: "L'élection du capitaine est lancée !" }
        format.json { render :show, status: :created, location: @vote }
      end
    else
      respond_to do |format|
        format.html { redirect_to @team, alert: "Il y a déjà un vote en cours..." }
        format.json { render :show, status: :created, location: @vote }
      end
    end
  end

  def election
    @vote = Vote.find(params[:vote])
    @team = @vote.team
    @joueur = current_user.teamings.where(team_id: @team.id, active:true).first
    @joueurs = @team.members.where(state:2)
    @majority = @joueurs.count / 2 + 1

    if params[:answer] == "true"
      @vote.counter += 1
      @vote.has_voted[@joueur.num_role] = true
    else
      @vote.has_voted[@joueur.num_role] = false
    end

    @vote.votes += 1
    @vote.save

    if @vote.votes >= @majority
      if @vote.counter >= @majority
        @vote.update_attribute(:result,true)
        @vote.save
        @captain = @vote.votable.teamings.where(team_id: @team.id, active: true).first
        @captain.captain = true
        @captain.save
        History.create(date: Time.now, team: @team, teaming: @captain, action:"captain")
        check_achievements(@captain.user,"votes")
        @joueurs.each do |joueur|
          Notification.create(recepteur: joueur, emetteur: current_user, category:"vote", action:"élu", notifiable: @team)
        end
      elsif @vote.counter < @majority && @vote.votes == @majority
        @vote.update_attribute(:result,false)
        @joueurs.each do |joueur|
          Notification.create(recepteur: joueur, emetteur: current_user, category:"vote", action:"pas-élu", notifiable: @team)
        end
      end
    end
    respond_to do |format|
      format.html { redirect_to @team, notice:"Vote envoyé !"}
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vote
      @vote = Vote.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vote_params
      params.require(:vote)
    end
end
