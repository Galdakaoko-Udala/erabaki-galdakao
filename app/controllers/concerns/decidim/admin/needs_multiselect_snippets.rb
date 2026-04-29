# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Admin
    module NeedsMultiselectSnippets
      extend ActiveSupport::Concern

      included do
        helper_method :snippets
      end

      def snippets
        return @snippets if @snippets

        @snippets = Decidim::Snippets.new

        @snippets.add(:select2, ActionController::Base.helpers.stylesheet_link_tag("select2.css"))
        @snippets.add(:select2, ActionController::Base.helpers.javascript_include_tag("resource_permissions_multiselect"))
        @snippets.add(:head, @snippets.for(:select2))

        @snippets
      end
    end
  end
end