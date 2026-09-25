# frozen_string_literal: true

class CreateGaldakaoZones < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_galdakao_census_galdakao_zones do |t|
      t.references :decidim_organization, null: false, index: { name: "index_galdakao_census_zones_on_organization_id" }
      t.string     :name, null: false
      t.timestamps
    end

    create_table :decidim_galdakao_census_galdakao_zone_streets do |t|
      t.references :zone,   null: false,
                            foreign_key: { to_table: :decidim_galdakao_census_galdakao_zones },
                            index: { name: "index_galdakao_census_zone_streets_on_zone_id" }
      t.references :street, null: false, index: { name: "index_galdakao_census_zone_streets_on_street_id" }
      t.integer    :numbers_constraint, default: 0, null: false
      t.string     :numbers_range
      t.timestamps
    end
  end
end
