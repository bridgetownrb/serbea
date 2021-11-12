Serbea::TemplateEngine.directive :form, ->(code, buffer) do
  model_name, space, params = code.lstrip.partition(%r(\s)m)
  model_name.chomp!(",")
  model_name = "#{model_name}," unless params.lstrip.start_with?("do", "{")

  buffer << "{%= form_with model: "
  buffer << model_name << " #{params}"
  buffer << " %}"
end

Serbea::TemplateEngine.directive :frame, ->(code, buffer) do
  buffer << "{%= turbo_frame_tag "
  buffer << code
  buffer << " %}"
end

%i(append prepend update replace remove before after).each do |action|
  Serbea::TemplateEngine.directive action, ->(code, buffer) do
    buffer << "{%= turbo_stream.#{action} "
    buffer << code
    buffer << " %}"
  end
end

Serbea::TemplateEngine.directive :_, ->(code, buffer) do
  tag_name, space, params = code.lstrip.partition(%r(\s)m)

  if tag_name.end_with?(":")
    tag_name.chomp!(":")
    tag_name = ":#{tag_name}" unless tag_name.start_with?(":")
  end

  buffer << "{%= tag.tag_string "
  buffer << tag_name << ", " << params
  buffer << " %}"
end
