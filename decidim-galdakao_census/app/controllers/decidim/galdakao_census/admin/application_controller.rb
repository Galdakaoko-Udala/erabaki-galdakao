# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Base controller for the census admin pages, shown in their own admin section.
      class ApplicationController < Decidim::Admin::ApplicationController
        layout "decidim/galdakao_census/admin/galdakao_census"

        def permission_class_chain
          [Decidim::GaldakaoCensus::Admin::Permissions] + super
        end
      end
    end
  end
end
