# frozen_string_literal: true

# NOTE: remove this when Rails is updated to 7.0.8.8 or higher

Rails.application.config.to_prepare do
  ActiveSupport::Cache::FileStore.class_eval do
    def file_path_key(path)
      fname = path[cache_path.to_s.size..-1].split(File::SEPARATOR, 4).last.delete(File::SEPARATOR)
      URI.decode_www_form_component(fname, Encoding::UTF_8)
    end
  end
end
