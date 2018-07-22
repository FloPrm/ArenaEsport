class PollingsController < ApplicationController
  respond_to :js

  def create
    @poll = Poll.find(params[:poll])
    @polling = Polling.new(polling_params)
    @polling.poll = @poll
    @polling.user = current_user
    @polling.save
  end

  private

  def polling_params
    params.require(:polling).permit(:vote)
  end

end
