class FeedbacksController < ApplicationController
  before_action :set_feedback

  def update
    @feedback.update(feedback_params)
    @notes = [@feedback.knowledge, @feedback.pedagogy, @feedback.behaviour]
    @feedback.average = (@notes.inject(0.0) { |sum, el| sum + el } / @notes.size).round(1)
    @feedback.save

    @mentor = @feedback.mentor
    @feedbacks = @mentor.feedbacks.where('average > ?', 0)
    @notes = @feedbacks.pluck(:average)
    @mentor.note = (@notes.inject(0.0) { |sum, el| sum + el } / @notes.size).round(1)
    @mentor.save
      @feedbacks = @mentor.feedbacks.where('average > ?', 0)
      if @feedback.mentorat.present?
        check_achievements(@feedback.mentorat.user,"feedbacks")
      elsif @feedback.user.present?
        check_achievements(@feedback.user,"feedbacks")
      end
      check_achievements(@feedback.mentor.user,"feedbacks")
      respond_to do |format|
        format.js
      end
  end

  private

  def set_feedback
    @feedback = Feedback.find(params[:id])
  end

  def feedback_params
    params.require(:feedback).permit(:knowledge, :pedagogy, :behaviour, :content)
  end

end
