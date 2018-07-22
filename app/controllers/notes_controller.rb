class NotesController < ApplicationController
  before_action :set_note, except: [:index, :create]
  respond_to :js

  def index
    authorize! :manage, :all
    @notes = Note.all.paginate(:page => params[:page])
  end

  def create
    @note = Note.new(note_params)
    @note.user = current_user
    @note.team_id = params[:team] unless params[:team].nil?
    @note.composition_id = params[:composition] unless params[:composition].nil?
    @note.save
  end

  def edit
  end

  def update
    @team = @note.team
    @note.update(note_params)
  end

  def destroy
    @team = @note.team
    @composition = @note.composition
    @note.destroy
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:body)
  end
end
