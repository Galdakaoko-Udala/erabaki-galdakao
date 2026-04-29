# frozen_string_literal: true

class CreateGaldakaoStreets < ActiveRecord::Migration[6.0]
  def change
    create_table :galdakao_streets do |t|
      t.string :name, null: false
      t.references :decidim_organization, null: false, foreign_key: { to_table: :decidim_organizations }

      t.timestamps
    end

    add_index :galdakao_streets, [:name, :decidim_organization_id], unique: true
  end
end