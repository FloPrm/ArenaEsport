class UrlsController < ApplicationController
  def show
    @url = Url.find_by_short(params[:short_url])
    redirect_to @url.original
  end
end
