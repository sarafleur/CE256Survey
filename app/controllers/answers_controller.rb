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
    session[:price_transit_pass_proposed] = 90
    #Store time duration for car
    response_car = HTTParty.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}&mode=driving")
    json_car = JSON.parse(response_car.body)
    session[:time_car] = json_car['routes'][0]['legs'][0]['duration']['text']
    #Store time duration for bikes
    response_bike = HTTParty.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}&mode=bicycling")
    json_bike = JSON.parse(response_bike.body)
    session[:time_bike] = json_bike['routes'][0]['legs'][0]['duration']['text']
    #Store time duration for walk
    response_walk = HTTParty.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}&mode=walking")
    json_walk = JSON.parse(response_walk.body)
    session[:time_walk] = json_walk['routes'][0]['legs'][0]['duration']['text']
    #Store time duration for transit and time walking to station
    response_transit = HTTParty.get("http://maps.googleapis.com/maps/api/directions/json?origin=#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}&mode=transit")
    json_transit = JSON.parse(response_transit.body)
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
    render('page4')
  end
end
