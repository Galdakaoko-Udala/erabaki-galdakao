# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    # A group of streets (and portal numbers) used to restrict permissions by address.
    class Zone < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"
      has_many :zone_streets, dependent: :destroy
      has_many :streets, through: :zone_streets

      validates :name, presence: true
    end
  end
end
