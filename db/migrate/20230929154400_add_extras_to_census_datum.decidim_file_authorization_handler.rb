# frozen_string_literal: true
# This migration comes from decidim_file_authorization_handler (originally 20221207143742)

class AddExtrasToCensusDatum < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_file_authorization_handler_census_data, :extras, :jsonb
  end
end
