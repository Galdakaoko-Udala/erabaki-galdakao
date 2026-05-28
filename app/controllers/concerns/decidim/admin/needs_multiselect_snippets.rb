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
        @snippets ||= Decidim::Snippets.new
      end
    end
  end
end
