class StimulusGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_controller
    new_controller = File.join("app/javascript/controllers/#{file_name}_controller.js") 

    template("controller.js", new_controller)
    gsub_file new_controller, "ReplaceMe", "#{file_name}"

    append_file "app/javascript/controllers/index.js" do
      "\nimport #{file_name}Controller, {string_identifier as #{file_name}_id} from \"./#{file_name}_controller\"\napplication.register(#{file_name}_id, #{file_name}Controller)"
    end

  end
end
