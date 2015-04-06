class AdminController < ApplicationController
  before_action :set_answer, only: [:show, :edit, :update, :destroy]

  def index
    render('index')
  end

end
