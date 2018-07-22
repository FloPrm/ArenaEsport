class DiscordController < ApplicationController

  def index
    response = {command: params[:command],name: "nom", lvlMin: "bronze", lvlMax: "gold", age: "15", schedule: "12H - 18H Semaine, 12H - 23H Week-End", missingRoles: "AdCarry"}
    render :json => response
  end

end
