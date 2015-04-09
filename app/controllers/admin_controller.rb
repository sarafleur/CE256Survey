require 'csv'

class AdminController < ApplicationController
  before_action :set_answer, only: [:show, :edit, :update, :destroy]

  def index
    render('index')
  end

  def data
    if params[:password_admin] == 'givemethedata' || session[:connected]
      session[:connected] = true
      if params['delete']
        Answer.find(params['delete']).destroy!
      end
      @answers = Answer.all
      @count = Answer.count()
      render('data')
    else
      flash[:message] = "The admin password is required to see the results"
      redirect_to '/admin'
    end
  end

  def export_csv
    @count = Answer.count()
    @answers = Answer.all
    @csv = Answer.to_csv
    render 'csv'
  end
end
