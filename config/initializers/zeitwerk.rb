Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "open_ai_client" => "OpenAIClient"
  )
end
