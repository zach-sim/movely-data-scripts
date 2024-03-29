# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_07_103511) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "area_units", force: :cascade do |t|
    t.text "name"
    t.geography "shape", limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "directions", force: :cascade do |t|
    t.bigint "from_au_id"
    t.bigint "to_au_id"
    t.geometry "path", limit: {:srid=>0, :type=>"geometry"}
    t.json "data"
    t.integer "type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["from_au_id"], name: "index_directions_on_from_au_id"
    t.index ["to_au_id"], name: "index_directions_on_to_au_id"
  end

end
