require 'rubygems'
require 'bundler'
require 'geokit'
require 'json'
require 'httparty'
require 'variable'
require 'functionHelper'

class AnswersController < ApplicationController
  before_action :set_answer, only: [:show, :edit, :update, :destroy]
  #helper AnswersHelper

####################################################################################################
    @@activity_table = ['Lunch','Leisure','Working Out','Shopping']
    @@cost_car_per_mile = 0.13
    @@cost_ecar_per_mile = 0.06
    @@cost_transit = 2.5
    @@cost_bikesharing_member_inf_30 = 0
    @@cost_bikesharing_member_sup_30 = 4
    @@cost_bikesharing_non_member_inf_30 = 9
    @@cost_bikesharing_non_member_sup_30 = 11
    @@GHG_car_per_mile = 0.870
    @@GHG_ecar_per_mile = 0.600
    @@GHG_transit_per_mile = 0.008
    @@GHG_ebike_per_mile = 0.010
    @@calories_car_per_hour = 140.0
    @@calories_bike_per_hour = 400.0
    @@calories_ebike_per_hour = 300.0
    @@calories_walk_per_hour = 270.0
    @@calories_transit_per_hour = 140.0
    @@time_walk_bike = [5,10,15]
    @@speed_ebike = 1/1.4 #relative to the speed of a regular bike
    @@price_bike_proposed = [90, 100, 110]
    @@income_possibilities = ['<20k', '20k - 50k', '50k - 80k', '> 80k']
    @@frequency_possibilities = ['everyday', '2-3 times a week', 'once a week', 'twice a month']
########################################################################################################

    def self.per_mile_to_per_meter(var)
      var / (1.61 * 1000)
    end

    def self.per_hour_to_per_sec(var)
      var / 3600
    end
    # delete the s when then is only one hour
    def self.sec_to_hour_string(duration)
      "#{duration/60} mins"
    end


    #Constants with adapted units: Do not modify
    @@cost_car_per_meter = per_mile_to_per_meter(@@cost_car_per_mile)
    @@cost_ecar_per_meter = per_mile_to_per_meter(@@cost_car_per_mile)
    @@GHG_car_per_meter = per_mile_to_per_meter(@@GHG_car_per_mile)
    @@GHG_ecar_per_meter = per_mile_to_per_meter(@@GHG_car_per_mile)
    @@GHG_transit_per_meter = per_mile_to_per_meter(@@GHG_transit_per_mile)
    @@GHG_ebike_per_meter = per_mile_to_per_meter(@@GHG_ebike_per_mile)
    @@calories_car_per_sec = per_hour_to_per_sec(@@calories_car_per_hour)
    @@calories_bike_per_sec = per_hour_to_per_sec(@@calories_bike_per_hour)
    @@calories_ebike_per_sec = per_hour_to_per_sec(@@calories_ebike_per_hour)
    @@calories_walk_per_sec = per_hour_to_per_sec(@@calories_walk_per_hour)
    @@calories_transit_per_sec = per_hour_to_per_sec(@@calories_transit_per_hour)

    @@maps_API_url = "http://maps.googleapis.com/maps/api/directions/json?origin="
    @@number_activities = @@activity_table.length
    @@bike_ebike_table = []
    ((@@number_activities + 1) / 2).times{@@bike_ebike_table.append('Bike')}
    ((@@number_activities + 2) / 2).times{@@bike_ebike_table.append('Electric Bike')}

    def self.generate_array(coordinates)
      session[:price_transit_pass_proposed] = @@price_bike_proposed.sample
      #Store time duration for car
      response_car = HTTParty.get(@@maps_API_url+coordinates+"&mode=driving")
      json_car = JSON.parse(response_car.body)
      status_car = json_car['status']
      if status_car != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_car] = json_car['routes'][0]['legs'][0]['duration']['text']
      session[:time_car_sec] = json_car['routes'][0]['legs'][0]['duration']['value']
      #In meters
      distance_car = json_car['routes'][0]['legs'][0]['distance']['value']
      cost_car = session[:has_e_car] ? @@cost_ecar_per_meter : @@cost_car_per_meter
      session[:cost_car] = (distance_car * cost_car).round(2)
      ghg_car = session[:has_e_car] ? @@GHG_ecar_per_meter : @@GHG_car_per_meter
      #FIXME: is rounf 2 enough ?
      session[:ghg_car] = (distance_car * ghg_car).round(4)
      #Store time duration for bikes
      response_bike = HTTParty.get(@@maps_API_url+coordinates+"&mode=bicycling")
      session[:url_bike] = @@maps_API_url+coordinates+"&mode=bicycling"
      json_bike = JSON.parse(response_bike.body)
      status_bike = json_bike['status']
      if status_bike != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_bike_google_sec] = json_bike['routes'][0]['legs'][0]['duration']['value']
      session[:time_bike_sec] = session[:has_e_bike] ? (session[:time_bike_google_sec] * @@speed_ebike).round : session[:time_bike_google_sec]
      session[:time_bike] = AnswersController::sec_to_hour_string(session[:time_bike_sec])
      distance_bike = json_bike['routes'][0]['legs'][0]['distance']['value']
      session[:calories_bike] = session[:has_e_bike] ? session[:time_bike_sec] * @@calories_ebike_per_sec : session[:time_bike_sec] * @@calories_bike_per_sec
      session[:calories_bike] = session[:calories_bike].round
      #Store time duration for walk
      response_walk = HTTParty.get(@@maps_API_url+coordinates+"&mode=walking")
      session[:url_walk] = @@maps_API_url+coordinates+"&mode=walking"
      json_walk = JSON.parse(response_walk.body)
      status_walk = json_walk['status']
      if status_walk != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_walk] = json_walk['routes'][0]['legs'][0]['duration']['text']
      session[:time_walk_sec] = json_walk['routes'][0]['legs'][0]['duration']['value']
      session[:calories_walk] = session[:time_walk_sec] * @@calories_walk_per_sec
      session[:calories_walk] = session[:calories_walk].round
      #Store time duration for transit and time walking to station
      response_transit = HTTParty.get(@@maps_API_url+coordinates+"&mode=transit")
      json_transit = JSON.parse(response_transit.body)
      status_transit = json_transit['status']
      if status_transit != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_transit_total] = json_transit['routes'][0]['legs'][0]['duration']['text']
      session[:time_transit_total_sec] = json_transit['routes'][0]['legs'][0]['duration']['value']
      steps = json_transit['routes'][0]['legs'][0]['steps']
      duration_walking = 0
      distance_walking = 0
      distance_transit = 0
      for step in steps
        if step['travel_mode'] == 'WALKING'
          duration_walking += step['duration']['value']
          distance_walking += step['distance']['value']
        else
          distance_transit += step['distance']['value']
        end
      end
      session[:time_transit_walk_sec] = duration_walking
      session[:time_transit_walk] = AnswersController::sec_to_hour_string(duration_walking)
      session[:ghg_transit] = distance_transit * @@GHG_transit_per_meter
      session[:calories_transit] = session[:time_transit_walk_sec] * @@calories_walk_per_sec
      session[:calories_transit] += duration_transit * @@calories_transit_per_sec
      session[:calories_transit] = session[:calories_transit].round

      #Store variables for bikesharing
      session[:time_bikesharing_walking_sec] = @@time_walk_bike.sample
      session[:time_bikesharing_bike_sec] = (session[:bike_or_ebike] == 'Bike') ? session[:time_bike_sec] : (session[:time_bike_sec] * @@speed_ebike).round
      session[:time_bikesharing_total_sec] = session[:time_bikesharing_walking_sec] + session[:time_bikesharing_bike_sec]
      session[:time_bikesharing_total] = AnswersController::sec_to_hour_string(session[:time_bikesharing_total_sec])
      session[:time_bikesharing_walking] = AnswersController::sec_to_hour_string(session[:time_bikesharing_walking_sec])
      session[:ghg_bikesharing] = session[:bike_or_ebike] == 'Bike' ? 0 : distance_bike * @@GHG_ebike_per_meter
      session[:calories_bikesharing] = (session[:bike_or_ebike] == 'Bike') ? session[:time_bikesharing_bike_sec] * @@calories_bike_per_sec : session[:time_bikesharing_bike_sec] * @@calories_ebike_per_sec
      session[:calories_bikesharing] += session[:time_bikesharing_walking_sec] * @@calories_walk_per_sec
      session[:calories_bikesharing] = session[:calories_bikesharing].round
    end

    def self.save_data
      @answer = Answer.new(
      :peopleId => session[:peopleId],
      :has_transit_pass => session[:has_transit_pass],
      :has_car => session[:has_car],
      :has_e_car => session[:has_e_car],
      :has_bike => session[:has_bike],
      :has_e_bike => session[:has_e_bike],
      :lat_origin => session[:lat_origin],
      :lat_destination => session[:lat_destination],
      :lon_origin => session[:lon_origin],
      :lon_destination => session[:lon_destination],
      :activity => session[:current_activity],
      :time_car => session[:time_car_sec],
      :time_bike => session[:time_bike_sec],
      :time_walk => session[:time_walk_sec],
      :time_transit_total => session[:time_transit_total_sec],
      :time_transit_walk => session[:time_transit_walk_sec],
      :price_transit_pass_proposed => session[:price_transit_pass_proposed],
      :wants_transit_pass => session[:wants_transit_pass],
      :age => session[:age],
      :income => session[:income],
      :frequency => session[:frequency],
      :time_bikesharing_total => session[:time_bikesharing_total_sec],
      :time_bikesharing_walking => session[:time_bikesharing_walking_sec],
      :bikesharing_option => session[:bike_or_ebike])
      @answer.save!
    end

    def open_page
      reset_session
      redirect_to '/new'
    end

    def new_survey
      render('new')
    end

    def new_survey_creation
      session[:peopleId] = Answer.nextPeopleId
      permutation_possibilities = @@activity_table.permutation.to_a
      session[:activity_table] = permutation_possibilities[rand(permutation_possibilities.length)]
      permutation_possibilities = @@bike_ebike_table.permutation.to_a
      session[:bike_ebike_table] = permutation_possibilities[rand(permutation_possibilities.length)]
      session[:activity_count] = 0
      session[:bike_or_ebike] = session[:bike_ebike_table][session[:activity_count]]
      session[:current_activity] = 'work'
      session[:income_possibilities] = @@income_possibilities
      session[:frequency_possibilities] = @@frequency_possibilities
      redirect_to '/page1'
    end

    def render_page1
      render('page1')
    end

    def answer_page1
      if params[:has_car] && params[:has_bike] && params[:has_transit_pass] && params[:age] && params[:income]
        session[:has_car] = (params[:has_car] == 'Yes')
        session[:has_bike] = (params[:has_bike] == 'Yes')
        session[:has_transit_pass] = (params[:has_transit_pass] == 'Yes')
        session[:age] = params[:age]
        session[:income] = params[:income]

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
      if params[:address_origin] && params[:address_destination] && params[:frequency] && params[:current_mode]
        session[:lat_origin] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_origin]).lat
        session[:lon_origin] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_origin]).lng
        session[:lat_destination] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_destination]).lat
        session[:lon_destination] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_destination]).lng
        session[:lat_home] = session[:lat_origin]
        session[:lon_home] = session[:lon_origin]
        session[:lat_work] = session[:lat_destination]
        session[:lon_work] = session[:lon_destination]
        session[:frequency] = params[:frequency]
        session[:current_mode] = params[:current_mode]
        redirect_to '/page3'
      else
        flash[:message] = "All the questions are required on this page."
        redirect_to '/page2'
      end
    end

    def render_page3
      coordinates = "#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}"
      session[:price_transit_pass_proposed] = @@price_bike_proposed.sample
      #Store time duration for car
      response_car = HTTParty.get(@@maps_API_url+coordinates+"&mode=driving")
      json_car = JSON.parse(response_car.body)
      status_car = json_car['status']
      if status_car != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_car] = json_car['routes'][0]['legs'][0]['duration']['text']
      session[:time_car_sec] = json_car['routes'][0]['legs'][0]['duration']['value']
      #In meters
      distance_car = json_car['routes'][0]['legs'][0]['distance']['value']
      cost_car = session[:has_e_car] ? @@cost_ecar_per_meter : @@cost_car_per_meter
      session[:cost_car] = (distance_car * cost_car).round(2)
      ghg_car = session[:has_e_car] ? @@GHG_ecar_per_meter : @@GHG_car_per_meter
      #FIXME: is rounf 2 enough ?
      session[:ghg_car] = (distance_car * ghg_car).round(2)
      session[:calories_car] = @@calories_car_per_sec * session[:time_car_sec]
      session[:calories_car] = session[:calories_car].round

      #Store time duration for bikes
      response_bike = HTTParty.get(@@maps_API_url+coordinates+"&mode=bicycling")
      session[:url_bike] = @@maps_API_url+coordinates+"&mode=bicycling"
      json_bike = JSON.parse(response_bike.body)
      status_bike = json_bike['status']
      if status_bike != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_bike_google_sec] = json_bike['routes'][0]['legs'][0]['duration']['value']
      session[:time_bike_sec] = session[:has_e_bike] ? (session[:time_bike_google_sec] * @@speed_ebike).round : session[:time_bike_google_sec]
      session[:time_bike] = AnswersController::sec_to_hour_string(session[:time_bike_sec])
      distance_bike = json_bike['routes'][0]['legs'][0]['distance']['value']
      session[:calories_bike] = session[:has_e_bike] ? session[:time_bike_sec] * @@calories_ebike_per_sec : session[:time_bike_sec] * @@calories_bike_per_sec
      session[:calories_bike] = session[:calories_bike].round
      #Store time duration for walk
      response_walk = HTTParty.get(@@maps_API_url+coordinates+"&mode=walking")
      session[:url_walk] = @@maps_API_url+coordinates+"&mode=walking"
      json_walk = JSON.parse(response_walk.body)
      status_walk = json_walk['status']
      if status_walk != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_walk_sec] = json_walk['routes'][0]['legs'][0]['duration']['value']
      session[:time_walk] = AnswersController::sec_to_hour_string(session[:time_walk_sec])
      session[:calories_walk] = session[:time_walk_sec] * @@calories_walk_per_sec
      session[:calories_walk] = session[:calories_walk].round
      #Store time duration for transit and time walking to station
      response_transit = HTTParty.get(@@maps_API_url+coordinates+"&mode=transit")
      json_transit = JSON.parse(response_transit.body)
      status_transit = json_transit['status']
      if status_transit != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_transit_total] = json_transit['routes'][0]['legs'][0]['duration']['text']
      session[:time_transit_total_sec] = json_transit['routes'][0]['legs'][0]['duration']['value']
      steps = json_transit['routes'][0]['legs'][0]['steps']
      duration_walking = 0
      distance_walking = 0
      distance_transit = 0
      duration_transit = 0
      for step in steps
        if step['travel_mode'] == 'WALKING'
          duration_walking += step['duration']['value']
          distance_walking += step['distance']['value']
        else
          distance_transit += step['distance']['value']
          duration_transit += step['duration']['value']
        end
      end
      session[:time_transit_walk_sec] = duration_walking
      session[:time_transit_walk] = AnswersController::sec_to_hour_string(duration_walking)
      session[:ghg_transit] = (distance_transit * @@GHG_transit_per_meter).round(2)
      session[:calories_transit] = session[:time_transit_walk_sec] * @@calories_walk_per_sec
      session[:calories_transit] += duration_transit * @@calories_transit_per_sec
      session[:cost_transit] = session[:has_transit_pass] ? 0 : @@cost_transit
      session[:calories_transit] = session[:calories_transit].round

      #Store variables for bikesharing
      session[:time_bikesharing_walking_sec] = @@time_walk_bike.sample
      session[:time_bikesharing_bike_sec] = (session[:bike_or_ebike] == 'Bike') ? session[:time_bike_sec] : (session[:time_bike_sec] * @@speed_ebike).round
      session[:time_bikesharing_total_sec] = session[:time_bikesharing_walking_sec] + session[:time_bikesharing_bike_sec]
      session[:time_bikesharing_total] = AnswersController::sec_to_hour_string(session[:time_bikesharing_total_sec])
      session[:time_bikesharing_walking] = AnswersController::sec_to_hour_string(session[:time_bikesharing_walking_sec])
      session[:ghg_bikesharing] = session[:bike_or_ebike] == 'Bike' ? 0 : distance_bike * @@GHG_ebike_per_meter
      session[:ghg_bikesharing] = session[:ghg_bikesharing].round(2)
      session[:calories_bikesharing] = (session[:bike_or_ebike] == 'Bike') ? session[:time_bikesharing_bike_sec] * @@calories_bike_per_sec : session[:time_bikesharing_bike_sec] * @@calories_ebike_per_sec
      session[:calories_bikesharing] += session[:time_bikesharing_walking_sec] * @@calories_walk_per_sec
      session[:calories_bikesharing] = session[:calories_bikesharing].round
      session[:cost_bikesharing_member] = (session[:time_bikesharing_total_sec] < 1800) ? @@cost_bikesharing_member_inf_30 : @@cost_bikesharing_member_sup_30
      session[:cost_bikesharing_non_member] = (session[:time_bikesharing_total_sec] < 1800) ? @@cost_bikesharing_non_member_inf_30 : @@cost_bikesharing_non_member_sup_30
      #AnswersController::generate_array(coordinates)
      render('page3')
    end

    def answer_page3
      if params[:wants_transit_pass] && params[:chosen_mode] && params[:chosen_mode_back]
        session[:wants_transit_pass] = (params[:wants_transit_pass] == 'Yes')
        session[:chosen_mode] = params[:chosen_mode]
        session[:chosen_mode_back] = params[:chosen_mode_back]
        #AnswersController::save_data
        @answer = Answer.new(
        :peopleId => session[:peopleId],
        :has_transit_pass => session[:has_transit_pass],
        :has_car => session[:has_car],
        :has_e_car => session[:has_e_car],
        :has_bike => session[:has_bike],
        :has_e_bike => session[:has_e_bike],
        :lat_origin => session[:lat_origin],
        :lat_destination => session[:lat_destination],
        :lon_origin => session[:lon_origin],
        :lon_destination => session[:lon_destination],
        :activity => session[:current_activity],
        :time_car => session[:time_car_sec],
        :time_bike => session[:time_bike_sec],
        :time_walk => session[:time_walk_sec],
        :time_transit_total => session[:time_transit_total_sec],
        :time_transit_walk => session[:time_transit_walk_sec],
        :price_transit_pass_proposed => session[:price_transit_pass_proposed],
        :wants_transit_pass => session[:wants_transit_pass],
        :age => session[:age],
        :income => session[:income],
        :frequency => session[:frequency],
        :time_bikesharing_total => session[:time_bikesharing_total_sec],
        :time_bikesharing_walking => session[:time_bikesharing_walking_sec],
        :bikesharing_option => session[:bike_or_ebike],
        :cost_car => session[:cost_car],
        :cost_transit => session[:cost_transit],
        :cost_bikesharing_member => session[:cost_bikesharing_member],
        :cost_bikesharing_non_member => session[:cost_bikesharing_non_member],
        :GHG_car => session[:ghg_car],
        :GHG_transit => session[:ghg_transit],
        :GHG_bikesharing => session[:ghg_bikesharing],
        :cal_car => session[:calories_car],
        :cal_bike => session[:calories_bike],
        :cal_transit => session[:calories_transit],
        :cal_walk => session[:calories_walk],
        :cal_bikesharing => session[:calories_bikesharing],
        :current_mode => session[:current_mode],
        :chosen_mode => session[:chosen_mode],
        :chosen_mode_back => session[:chosen_mode_back])
        @answer.save!
        redirect_to('/activity1/')
      else
        flash[:message] = "All the questions are required on this page."
        redirect_to '/page3'
      end
    end

    def render_activity1
      if session[:activity_count] >= @@number_activities
        redirect_to('/last')
      else
        session[:current_activity] = session[:activity_table][session[:activity_count]]
        session[:activity_count] += 1
        session[:bike_or_ebike] = session[:bike_ebike_table][session[:activity_count]]
        render('activity1')
      end
    end

    def answer_activity1
      if params[:address_destination] && params[:origin] && params[:frequency] && params[:current_mode]
        session[:lat_destination] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_destination]).lat
        session[:lon_destination] = Geokit::Geocoders::GoogleGeocoder.geocode(params[:address_destination]).lng
        session[:lat_origin] = (params[:address_destination] == 'Work') ? session[:lat_work]: session[:lat_home]
        session[:lon_origin] = (params[:address_destination] == 'Work') ? session[:lon_work]: session[:lon_home]
        session[:frequency] = params[:frequency]
        session[:current_mode] = params[:current_mode]
        redirect_to '/activity2'
      else
        flash[:message] = "All the questions are required on this page."
        redirect_to '/activity1'
      end
    end

    def render_activity2
      coordinates = "#{session[:lat_origin]},#{session[:lon_origin]}&destination=#{session[:lat_destination]},#{session[:lon_destination]}"
      session[:price_transit_pass_proposed] = @@price_bike_proposed.sample
      #Store time duration for car
      response_car = HTTParty.get(@@maps_API_url+coordinates+"&mode=driving")
      json_car = JSON.parse(response_car.body)
      status_car = json_car['status']
      if status_car != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_car] = json_car['routes'][0]['legs'][0]['duration']['text']
      session[:time_car_sec] = json_car['routes'][0]['legs'][0]['duration']['value']
      #In meters
      distance_car = json_car['routes'][0]['legs'][0]['distance']['value']
      cost_car = session[:has_e_car] ? @@cost_ecar_per_meter : @@cost_car_per_meter
      session[:cost_car] = (distance_car * cost_car).round(2)
      ghg_car = session[:has_e_car] ? @@GHG_ecar_per_meter : @@GHG_car_per_meter
      #FIXME: is rounf 2 enough ?
      session[:ghg_car] = (distance_car * ghg_car).round(2)
      session[:calories_car] = @@calories_car_per_sec * session[:time_car_sec]
      session[:calories_car] = session[:calories_car].round

      #Store time duration for bikes
      response_bike = HTTParty.get(@@maps_API_url+coordinates+"&mode=bicycling")
      session[:url_bike] = @@maps_API_url+coordinates+"&mode=bicycling"
      json_bike = JSON.parse(response_bike.body)
      status_bike = json_bike['status']
      if status_bike != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_bike_google_sec] = json_bike['routes'][0]['legs'][0]['duration']['value']
      session[:time_bike_sec] = session[:has_e_bike] ? (session[:time_bike_google_sec] * @@speed_ebike).round : session[:time_bike_google_sec]
      session[:time_bike] = AnswersController::sec_to_hour_string(session[:time_bike_sec])
      distance_bike = json_bike['routes'][0]['legs'][0]['distance']['value']
      session[:calories_bike] = session[:has_e_bike] ? session[:time_bike_sec] * @@calories_ebike_per_sec : session[:time_bike_sec] * @@calories_bike_per_sec
      session[:calories_bike] = session[:calories_bike].round
      #Store time duration for walk
      response_walk = HTTParty.get(@@maps_API_url+coordinates+"&mode=walking")
      session[:url_walk] = @@maps_API_url+coordinates+"&mode=walking"
      json_walk = JSON.parse(response_walk.body)
      status_walk = json_walk['status']
      if status_walk != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_walk_sec] = json_walk['routes'][0]['legs'][0]['duration']['value']
      session[:time_walk] = AnswersController::sec_to_hour_string(session[:time_walk_sec])
      session[:calories_walk] = session[:time_walk_sec] * @@calories_walk_per_sec
      session[:calories_walk] = session[:calories_walk].round
      #Store time duration for transit and time walking to station
      response_transit = HTTParty.get(@@maps_API_url+coordinates+"&mode=transit")
      json_transit = JSON.parse(response_transit.body)
      status_transit = json_transit['status']
      if status_transit != 'OK'
        flash[:message] = "It looks like your adress is not valid. Please try again"
        redirect_to '/page2'
      end
      session[:time_transit_total] = json_transit['routes'][0]['legs'][0]['duration']['text']
      session[:time_transit_total_sec] = json_transit['routes'][0]['legs'][0]['duration']['value']
      steps = json_transit['routes'][0]['legs'][0]['steps']
      duration_walking = 0
      distance_walking = 0
      distance_transit = 0
      duration_transit = 0
      for step in steps
        if step['travel_mode'] == 'WALKING'
          duration_walking += step['duration']['value']
          distance_walking += step['distance']['value']
        else
          distance_transit += step['distance']['value']
          duration_transit += step['duration']['value']
        end
      end
      session[:time_transit_walk_sec] = duration_walking
      session[:time_transit_walk] = AnswersController::sec_to_hour_string(duration_walking)
      session[:ghg_transit] = (distance_transit * @@GHG_transit_per_meter).round(2)
      session[:calories_transit] = session[:time_transit_walk_sec] * @@calories_walk_per_sec
      session[:calories_transit] += duration_transit * @@calories_transit_per_sec
      session[:cost_transit] = session[:has_transit_pass] ? 0 : @@cost_transit
      session[:calories_transit] = session[:calories_transit].round

      #Store variables for bikesharing
      session[:time_bikesharing_walking_sec] = @@time_walk_bike.sample
      session[:time_bikesharing_bike_sec] = (session[:bike_or_ebike] == 'Bike') ? session[:time_bike_sec] : (session[:time_bike_sec] * @@speed_ebike).round
      session[:time_bikesharing_total_sec] = session[:time_bikesharing_walking_sec] + session[:time_bikesharing_bike_sec]
      session[:time_bikesharing_total] = AnswersController::sec_to_hour_string(session[:time_bikesharing_total_sec])
      session[:time_bikesharing_walking] = AnswersController::sec_to_hour_string(session[:time_bikesharing_walking_sec])
      session[:ghg_bikesharing] = session[:bike_or_ebike] == 'Bike' ? 0 : distance_bike * @@GHG_ebike_per_meter
      session[:ghg_bikesharing] = session[:ghg_bikesharing].round(2)
      session[:calories_bikesharing] = (session[:bike_or_ebike] == 'Bike') ? session[:time_bikesharing_bike_sec] * @@calories_bike_per_sec : session[:time_bikesharing_bike_sec] * @@calories_ebike_per_sec
      session[:calories_bikesharing] += session[:time_bikesharing_walking_sec] * @@calories_walk_per_sec
      session[:calories_bikesharing] = session[:calories_bikesharing].round
      session[:cost_bikesharing_member] = (session[:time_bikesharing_total_sec] < 1800) ? @@cost_bikesharing_member_inf_30 : @@cost_bikesharing_member_sup_30
      session[:cost_bikesharing_non_member] = (session[:time_bikesharing_total_sec] < 1800) ? @@cost_bikesharing_non_member_inf_30 : @@cost_bikesharing_non_member_sup_30
      #AnswersController::generate_array(coordinates)
      render('activity2')
    end

    def answer_activity2
      if params[:wants_transit_pass] && params[:chosen_mode] && params[:chosen_mode_back]
        session[:wants_transit_pass] = (params[:wants_transit_pass] == 'Yes')
        session[:chosen_mode] = params[:chosen_mode]
        session[:chosen_mode_back] = params[:chosen_mode_back]
        #AnswersController::save_data
        @answer = Answer.new(
        :peopleId => session[:peopleId],
        :has_transit_pass => session[:has_transit_pass],
        :has_car => session[:has_car],
        :has_e_car => session[:has_e_car],
        :has_bike => session[:has_bike],
        :has_e_bike => session[:has_e_bike],
        :lat_origin => session[:lat_origin],
        :lat_destination => session[:lat_destination],
        :lon_origin => session[:lon_origin],
        :lon_destination => session[:lon_destination],
        :activity => session[:current_activity],
        :time_car => session[:time_car_sec],
        :time_bike => session[:time_bike_sec],
        :time_walk => session[:time_walk_sec],
        :time_transit_total => session[:time_transit_total_sec],
        :time_transit_walk => session[:time_transit_walk_sec],
        :price_transit_pass_proposed => session[:price_transit_pass_proposed],
        :wants_transit_pass => session[:wants_transit_pass],
        :age => session[:age],
        :income => session[:income],
        :frequency => session[:frequency],
        :time_bikesharing_total => session[:time_bikesharing_total_sec],
        :time_bikesharing_walking => session[:time_bikesharing_walking_sec],
        :bikesharing_option => session[:bike_or_ebike],
        :cost_car => session[:cost_car],
        :cost_transit => session[:cost_transit],
        :cost_bikesharing_member => session[:cost_bikesharing_member],
        :cost_bikesharing_non_member => session[:cost_bikesharing_non_member],
        :GHG_car => session[:ghg_car],
        :GHG_transit => session[:ghg_transit],
        :GHG_bikesharing => session[:ghg_bikesharing],
        :cal_car => session[:calories_car],
        :cal_bike => session[:calories_bike],
        :cal_transit => session[:calories_transit],
        :cal_walk => session[:calories_walk],
        :cal_bikesharing => session[:calories_bikesharing],
        :current_mode => session[:current_mode],
        :chosen_mode => session[:chosen_mode],
        :chosen_mode_back => session[:chosen_mode_back])
        @answer.save!
        redirect_to('/activity1/')
      else
        flash[:message] = "All the questions are required on this page."
        redirect_to '/activity2'
      end
    end

    def render_last
      render('last')
    end
end
