Rails.application.config.assets.configure do |env|
  env.cache = ActiveSupport::Cache.lookup_store(:memory_store)
end 