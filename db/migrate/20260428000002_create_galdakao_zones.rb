class CreateGaldakaoZones < ActiveRecord::Migration[7.0]
  def change
    create_table :galdakao_zones do |t|
      t.references :decidim_organization, null: false, index: true
      t.string     :name, null: false
      t.timestamps
    end

    create_table :galdakao_zone_streets do |t|
      t.references :zone,   null: false, foreign_key: { to_table: :galdakao_zones }, index: true
      t.references :street, null: false, index: true
      t.integer    :numbers_constraint, default: 0, null: false
      t.string     :numbers_range
      t.timestamps
    end
  end
end
