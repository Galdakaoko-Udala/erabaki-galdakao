# frozen_string_literal: true

namespace :fix_accountability do
  desc "Fix accountability taxonomies"
  task taxonomies: :environment do
    Decidim::Component.where(manifest_name: :accountability).each do |component|
      all_results = Decidim::Accountability::Result.where(component:)
      next unless all_results.exists?

      # find the higher hierarchy children taxonomy in all results
      higher_taxonomy = nil
      all_results.each do |result|
        result.taxonomies.each do |taxonomy|
          higher_taxonomy = taxonomy if higher_taxonomy.nil? || taxonomy.part_of.size < higher_taxonomy.part_of.size
        end
      end
      higher_parent = higher_taxonomy&.parent&.parent
      next unless higher_parent
      next if higher_parent.root?

      puts "Component #{component.id} - #{component.name.values} Space #{component.participatory_space.id} - #{component.participatory_space.title.values}"
      puts "  Total results: #{all_results.count}"
      puts "  Higher taxonomy parent: #{higher_parent.id} - #{higher_parent.name.values}"
      higher_parent.update!(parent_id: nil)
      puts "  Promoted taxonomy #{higher_parent.id} to root."
      filter = higher_parent.taxonomy_filters.create!
      puts "  Created filter #{filter.id}"
      Decidim::Taxonomy.part_of(higher_parent.id).each do |taxonomy|
        next if taxonomy.root?

        filter.filter_items.create!(taxonomy_item: taxonomy)
        puts "    Added taxonomy #{taxonomy.id} to filter"
      end
      puts "  Adding filter to component settings"
      settings = component[:settings] || {}
      settings["global"] ||= {}
      settings["global"]["taxonomy_filters"] ||= []
      settings["global"]["taxonomy_filters"] << filter.id.to_s
      component.save!
      puts "  Component settings updated. Filters now: #{settings["global"]["taxonomy_filters"]}."
    end
  end
end
