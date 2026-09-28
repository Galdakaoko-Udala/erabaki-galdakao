# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Base controller for the census admin pages, shown in the participants section.
      class ApplicationController < Decidim::Admin::ApplicationController
        layout "decidim/admin/users"

        def permission_class_chain
          [Decidim::GaldakaoCensus::Admin::Permissions] + super
        end
      end
    end
  end
end
