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

ActiveRecord::Schema.define(version: 2020_11_12_020619) do

  create_table "channels", force: :cascade do |t|
    t.string "slack_channel_id", null: false
    t.string "reaction_id", null: false
    t.string "org_repo", null: false
    t.string "labels"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["slack_channel_id", "reaction_id"], name: "index_channels_on_slack_channel_id_and_reaction_id", unique: true
  end

end
