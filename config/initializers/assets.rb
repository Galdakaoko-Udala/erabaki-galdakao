# frozen_string_literal: true

# Precompila los assets de select2 y el multiselect de calles
# para que estén disponibles en el panel de administración de Galdakao.
Rails.application.config.assets.precompile += %w[
  select2.js
  select2.css
  select2-foundation-theme.css
  resource_permissions_multiselect.js
]