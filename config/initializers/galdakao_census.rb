# frozen_string_literal: true

# Autoload de las clases de Galdakao y registro de rutas del engine de admin.
Rails.application.config.to_prepare do
  GaldakaoStreet
  GaldakaoWebservice
  CensusActionAuthorizer

  Decidim::Admin::Engine.routes.draw do
    resources :galdakao, only: [:index] do
      collection do
        get  :streets
        post :sync
        post :check
      end
    end
    scope "/galdakao", as: :galdakao do
      resources :zones do
        resources :zone_streets
      end
    end
  end
end
