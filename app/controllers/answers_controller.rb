class AnswersController < ApplicationController
  before_action :set_answer, only: [:show, :edit, :update, :destroy]

  def open_page
    redirect_to '/new'
  end

  def new_survey
    render('new')
  end

  def new_survey_creation
    redirect_to '/page1'
  end

  def render_page1
    render('page1')
  end

  def answer_page1
    if params[:has_car] && params[:has_bike] && params[:has_transit_pass]
      session[:has_car] = (params[:has_car] == 'Yes')
      session[:has_bike] = (params[:has_bike] == 'Yes')
      session[:has_transit_pass] = (params[:has_transit_pass] == 'Yes')

      if session[:has_car] || session[:has_bike]
        redirect_to '/page1bis'
      else
        redirect_to '/page2'
      end
    else
      flash[:message] = "All the questions are required on this page."
      redirect_to '/page1'
    end
  end

  def render_page1bis
    render('page1bis')
  end

  def answer_page1bis
    if session[:has_car] && session[:has_bike]
      if params[:has_e_car] && params[:has_e_bike]
        session[:has_e_car] = (params[:has_e_car] == 'Yes')
        session[:has_e_bike] = (params[:has_e_bike] == 'Yes')
        redirect_to '/page2'
      else
        flash[:message] = "All the questions are required on this page."
        redirect_to '/page1bis'
      end
    else
      if session[:has_car]
        if params[:has_e_car]
          session[:has_e_car] = (params[:has_e_car] == 'Yes')
          redirect_to '/page2'
        else
          flash[:message] = "All the questions are required on this page."
          redirect_to '/page1bis'
        end
      else
        if params[:has_e_bike]
          session[:has_e_bike] = (params[:has_e_bike] == 'Yes')
          redirect_to '/page2'
        else
          flash[:message] = "All the questions are required on this page."
          redirect_to '/page1bis'
        end
      end
    end
  end

  def render_page2
    render('page2')
  end





















  # GET /answers
  # GET /answers.json
  def index
    @answers = Answer.all
  end

  # GET /answers/1
  # GET /answers/1.json
  def show
  end

  # GET /answers/new
  def new
    @answer = Answer.new
  end

  # GET /answers/1/edit
  def edit
  end

  # POST /answers
  # POST /answers.json
  def create
    @answer = Answer.new(answer_params)

    respond_to do |format|
      if @answer.save
        format.html { redirect_to_to @answer, notice: 'Answer was successfully created.' }
        format.json { render :show, status: :created, location: @answer }
      else
        format.html { render :new }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /answers/1
  # PATCH/PUT /answers/1.json
  def update
    respond_to do |format|
      if @answer.update(answer_params)
        format.html { redirect_to_to @answer, notice: 'Answer was successfully updated.' }
        format.json { render :show, status: :ok, location: @answer }
      else
        format.html { render :edit }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /answers/1
  # DELETE /answers/1.json
  def destroy
    @answer.destroy
    respond_to do |format|
      format.html { redirect_to_to answers_url, notice: 'Answer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_answer
      @answer = Answer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def answer_params
      params[:answer]
    end
end
