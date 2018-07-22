class PlanningsController < ApplicationController
  before_action :set_planning

  def edit
    respond_to do |format|
      format.html { redirect_to current_user.team, alert: "Problème de chargement de la fenêtre d'édition du planning." }
      format.js
    end
  end

  def update
    @team = Team.find(params[:team])
    @planning.update(planning_params)
    respond_to do |format|
      format.html { redirect_to @team }
      format.js
    end
  end

  private

  def set_planning
    @planning = Planning.find(params[:id])
  end

  def planning_params
    params.require(:planning).permit(:lun, :mar, :mer, :jeu, :ven, :sam, :dim)
  end

end
