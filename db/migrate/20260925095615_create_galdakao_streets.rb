# frozen_string_literal: true

class CreateGaldakaoStreets < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_galdakao_census_galdakao_streets do |t|
      t.string :name, null: false
      t.references :decidim_organization, null: false,
                                          foreign_key: { to_table: :decidim_organizations },
                                          index: { name: "index_galdakao_census_streets_on_organization_id" }

      t.timestamps
    end

    add_index :decidim_galdakao_census_galdakao_streets, [:name, :decidim_organization_id],
              unique: true, name: "index_galdakao_census_streets_on_name_and_organization"
  end
end
