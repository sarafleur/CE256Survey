# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150410050237) do

  create_table "answers", force: :cascade do |t|
    t.boolean  "has_transit_pass"
    t.boolean  "has_car"
    t.boolean  "has_e_car"
    t.boolean  "has_bike"
    t.boolean  "has_e_bike"
    t.float    "lat_origin"
    t.float    "lat_destination"
    t.float    "lon_origin"
    t.float    "lon_destination"
    t.string   "activity"
    t.float    "time_car"
    t.float    "time_bike"
    t.float    "time_walk"
    t.float    "time_transit_total"
    t.float    "time_transit_walk"
    t.float    "price_transit_pass_proposed"
    t.boolean  "wants_transit_pass"
    t.integer  "age"
    t.string   "income"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "peopleId"
    t.text     "frequency"
    t.float    "time_bikesharing_total"
    t.float    "time_bikesharing_walking"
    t.string   "bikesharing_option"
    t.float    "cost_car"
    t.float    "cost_transit"
    t.float    "cost_bikesharing_member"
    t.float    "cost_bikesharing_non_member"
    t.float    "GHG_car"
    t.float    "GHG_transit"
    t.float    "GHG_bikesharing"
    t.float    "cal_car"
    t.float    "cal_bike"
    t.float    "cal_transit"
    t.float    "cal_walk"
    t.float    "cal_bikesharing"
    t.text     "current_mode"
    t.text     "chosen_mode"
    t.text     "chosen_mode_back"
  end

end
