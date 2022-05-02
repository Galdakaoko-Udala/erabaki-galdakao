# This migration comes from decidim_file_authorization_handler (originally 20171110120821)

# frozen_string_literal: true

class CreateDecidimFileAuthorizationHandlerCensusDatum < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_file_authorization_handler_census_data do |t|
      t.references :decidim_organization, index: { name: "decidim_census_data_org_id_index" }
      t.string :id_document
      t.date :birthdate

      # The rows in this table are immutable (insert or delete, not update)
      # To explicitly reflect this fact there is no `updated_at` column
      t.datetime "created_at", null: false
    end
  end
end
