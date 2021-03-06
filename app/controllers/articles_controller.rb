class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :check_login, only: [:new, :edit]

  #Crud des articles du blog, rien de particulier ici.

  # GET /articles
  # GET /articles.json
  def index
    @articles = Article.all
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
  end

  # GET /articles/new
  def new
    if user_signed_in?
      @article = Article.new
    else
      redirect_to articles_path, alert: 'Vous n\'avez pas accès à ce contenu.'
    end

  end

  # GET /articles/1/edit
  def edit
    unless current_user.id == @article.user_id
      redirect_to articles_path, alert: 'Vous n\'avez pas accès à ce contenu.'
    end
  end

  # POST /articles
  # POST /articles.json
  def create

    @article = Article.new(article_params)

    @article.user = current_user

    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, notice: 'Article was successfully created.' }
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1
  # PATCH/PUT /articles/1.json
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to @article, notice: 'Article was successfully updated.' }
        format.json { render :show, status: :ok, location: @article }
      else
        format.html { render :edit }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @article.destroy
    respond_to do |format|
      format.html { redirect_to articles_url, notice: 'Article was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.find(params[:id])
    end

    def check_login
      unless user_signed_in?
        redirect_to articles_path, alert: 'Vous n\'avez pas accès à ce contenu.'
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params
      params.require(:article).permit(:title, :body)
    end
end
