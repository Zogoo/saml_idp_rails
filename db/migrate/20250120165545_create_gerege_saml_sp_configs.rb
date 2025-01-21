class CreateGeregeSamlSpConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :gerege_saml_sp_configs do |t|
      # For identification
      t.string :name
      # SP attributes
      t.string :display_name
      t.string :entity_id
      t.text :name_id_formats, default: '[]'
      t.text :assertion_consumer_services, default: '[]'
      t.string :signing_certificate
      t.string :encryption_certificate
      t.boolean :sign_assertions
      t.boolean :sign_authn_request
      t.text :single_logout_services, default: '{}'
      t.text :contact_person, default: '{}'
      # IdP attributes
      t.string :certificate
      t.string :private_key
      t.string :pv_key_password
      t.string :relay_state
      t.string :name_id_attribute
      t.text :saml_attributes, default: '{}'
      # Optional storage for SP metadata
      t.text :raw_metadata

      # Public UUID for SP
      if connection.adapter_name.downcase.starts_with?('mysql')
        t.string :uuid, null: false, default: -> { "UUID()" }
      elsif connection.adapter_name.downcase.starts_with?('postgresql')
        t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
      else
        t.string :uuid, null: false
      end

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        if connection.adapter_name.downcase.starts_with?('postgresql')
          change_column :gerege_saml_sp_configs, :name_id_formats, :jsonb, using: 'name_id_formats::jsonb'
          change_column :gerege_saml_sp_configs, :assertion_consumer_services, :jsonb, using: 'assertion_consumer_services::jsonb'
          change_column :gerege_saml_sp_configs, :single_logout_services, :jsonb, using: 'single_logout_services::jsonb'
          change_column :gerege_saml_sp_configs, :contact_person, :jsonb, using: 'contact_person::jsonb'
          change_column :gerege_saml_sp_configs, :saml_attributes, :jsonb, using: 'saml_attributes::jsonb'
        elsif connection.adapter_name.downcase.starts_with?('mysql')
          change_column :gerege_saml_sp_configs, :name_id_formats, :json, using: 'name_id_formats::json'
          change_column :gerege_saml_sp_configs, :assertion_consumer_services, :json, using: 'assertion_consumer_services::json'
          change_column :gerege_saml_sp_configs, :single_logout_services, :json, using: 'single_logout_services::json'
          change_column :gerege_saml_sp_configs, :contact_person, :json, using: 'contact_person::json'
          change_column :gerege_saml_sp_configs, :saml_attributes, :json, using: 'saml_attributes::json'
        end
      end
    end
  end
end
