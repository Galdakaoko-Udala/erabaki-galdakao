# frozen_string_literal: true

module Decidim
  module Erabaki
    module ProposalSerializerOverride
      extend ActiveSupport::Concern

      # Public: Exports a hash with the serialized data for this proposal.
      def serialize
        {
          id: proposal.id,
          author: {
            **author_fields
          },
          taxonomies:,
          participatory_space: {
            id: proposal.participatory_space.id,
            url: Decidim::ResourceLocatorPresenter.new(proposal.participatory_space).url
          },
          component: { id: component.id },
          title: proposal.title,
          body: convert_to_plain_text(proposal.body),
          address: proposal.address,
          latitude: proposal.latitude,
          longitude: proposal.longitude,
          state: proposal.state.to_s,
          state_published_at: proposal.state_published_at,
          reference: proposal.reference,
          answer: ensure_translatable(proposal.answer),
          answered_at: proposal.answered_at,
          votes: proposal.proposal_votes_count,
          likes: {
            total_count: proposal.likes.size,
            user_likes:
          },
          comments: proposal.comments_count,
          attachments: proposal.attachments.size,
          follows_count: proposal.follows_count,
          published_at: proposal.published_at,
          url:,
          meeting_urls: meetings,
          related_proposals:,
          is_amend: proposal.emendation?,
          original_proposal: {
            title: proposal&.amendable&.title,
            url: original_proposal_url
          },
          withdrawn: proposal.withdrawn?,
          withdrawn_at: proposal.withdrawn_at,
          created_at: proposal.created_at,
          updated_at: proposal.updated_at,
          created_in_meeting: proposal.created_in_meeting,
          coauthorships_count: proposal.coauthorships_count,
          cost: proposal.cost,
          cost_report: proposal.cost_report,
          execution_period: proposal.execution_period
        }
      end
    end
  end
end
