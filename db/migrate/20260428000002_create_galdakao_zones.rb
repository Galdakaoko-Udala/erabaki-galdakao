class CreateGaldakaoZones < ActiveRecord::Migration[7.0]
  def change
    create_table :galdakao_zones do |t|
      t.references :decidim_organization, null: false, index: true
      t.references :street,              null: false, index: true
      t.integer    :numbers_constraint,  default: 0,  null: false
      t.string     :numbers_range
      t.string     :name

      t.timestamps
    end
  end
end