# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_01_20_165545) do
  create_table "gerege_saml_sp_configs", force: :cascade do |t|
    t.string "name"
    t.string "display_name"
    t.string "entity_id"
    t.text "name_id_formats", default: "[]"
    t.text "assertion_consumer_services", default: "[]"
    t.string "signing_certificate"
    t.string "encryption_certificate"
    t.boolean "sign_assertions"
    t.boolean "sign_authn_request"
    t.text "single_logout_services", default: "{}"
    t.text "contact_person", default: "{}"
    t.string "certificate"
    t.string "private_key"
    t.string "pv_key_password"
    t.string "relay_state"
    t.string "name_id_attribute"
    t.text "saml_attributes", default: "{}"
    t.text "raw_metadata"
    t.string "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
