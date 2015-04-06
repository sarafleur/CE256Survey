require 'rubygems'
require 'bundler'
require 'geokit'
require 'json'
require 'httparty'

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

  def answer_page2
    if params[:address_origin] && params[:address_destination]
      session[:lat_origin] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_origin]).lat
      session[:lon_origin] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_origin]).lng
      session[:lat_destination] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_destination]).lat
      session[:lon_destination] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_destination]).lng
      redirect_to '/page3'
    else
      flash[:message] = "All the questions are required on this page."
      redirect_to '/page2'
    end
  end

  def render_page3
    #FIXME: is it the way we want to choose?
    session[:price_transit_pass_proposed] = [90, 100, 110].sample
    #Store time duration for car
    response_car = HTTParty.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}&mode=driving")
    json_car = JSON.parse(response_car.body)
    status_car = json_car['status']
    if status_car != 'OK'
      flash[:message] = "It looks like your adress is not valid. Please try again"
      redirect_to '/page2'
    end
    session[:time_car] = json_car['routes'][0]['legs'][0]['duration']['text']
    #In meters
    distance_car = json_car['routes'][0]['legs'][0]['distance']['value']
    #FIXME: Cost/meter for a car: current source http://commutesolutions.org/external/calc.html
    cost_per_meter = 1.37 / (1.61 * 1000)
    session[:cost_car] = (distance_car * cost_per_meter).round(2)
    #Store time duration for bikes
    response_bike = HTTParty.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}&mode=bicycling")
    json_bike = JSON.parse(response_bike.body)
    status_bike = json_bike['status']
    if status_bike != 'OK'
      flash[:message] = "It looks like your adress is not valid. Please try again"
      redirect_to '/page2'
    end
    session[:time_bike] = json_bike['routes'][0]['legs'][0]['duration']['text']
    session[:time_bike_sec] = json_bike['routes'][0]['legs'][0]['duration']['value']
    #Store time duration for walk
    response_walk = HTTParty.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}&mode=walking")
    json_walk = JSON.parse(response_walk.body)
    status_walk = json_walk['status']
    if status_walk != 'OK'
      flash[:message] = "It looks like your adress is not valid. Please try again"
      redirect_to '/page2'
    end
    session[:time_walk] = json_walk['routes'][0]['legs'][0]['duration']['text']
    #Store time duration for transit and time walking to station
    response_transit = HTTParty.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}&mode=transit")
    json_transit = JSON.parse(response_transit.body)
    status_transit = json_transit['status']
    if status_transit != 'OK'
      flash[:message] = "It looks like your adress is not valid. Please try again"
      redirect_to '/page2'
    end
    session[:time_transit_total] = json_transit['routes'][0]['legs'][0]['duration']['text']
    steps = json_transit['routes'][0]['legs'][0]['steps']
    duration_walking = 0
    for step in steps
      if step['travel_mode'] == 'WALKING'
        duration_walking += step['duration']['value']
      end
    end
    session[:time_transit_walk] = "#{duration_walking/3600} hours #{(duration_walking%3600)/60} mins"
    render('page3')
  end

  def answer_page3
    if params[:wants_transit_pass]
      session[:wants_transit_pass] = params[:wants_transit_pass]
      redirect_to('/page4')
    else
      flash[:message] = "All the questions are required on this page."
      redirect_to '/page3'
    end
  end

  def render_page4
    session[:income_possibilities] =['<20k', '20k - 50k', '50k - 80k', '> 80k']
    render('page4')
  end

  def answer_page4
    if params[:age] && params[:income]
      session[:age] = params[:age]
      session[:income] = params[:income]
      redirect_to('/page5')
    else
      flash[:message] = "All the questions are required on this page."
      redirect_to '/page4'
    end
  end

  def render_page5
    @answer = Answer.new(
    :has_transit_pass => session[:has_transit_pass],
    :has_car => session[:has_car],
    :has_e_car => session[:has_e_car],
    :has_bike => session[:has_bike],
    :has_e_bike => session[:has_e_bike],
    :lat_origin => session[:lat_origin],
    :lat_destination => session[:lat_destination],
    :lon_origin => session[:lon_origin],
    :lon_destination => session[:lon_destination],
    :activity => 'work',
    :time_car => session[:time_car],
    :time_bike => session[:time_bike],
    :time_walk => session[:time_walk],
    :time_transit_total => session[:time_transit_total],
    :time_transit_walk => session[:time_transit_walk],
    :price_transit_pass_proposed => session[:price_transit_pass_proposed],
    :wants_transit_pass => session[:wants_transit_pass],
    :age => session[:age],
    :income => session[:income])
    @answer.save!
    render('page5')
  end
end
