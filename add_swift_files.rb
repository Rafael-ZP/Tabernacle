require 'xcodeproj'

project_path = 'tabernacle.xcodeproj'
project = Xcodeproj::Project.open(project_path)

main_target = project.targets.find { |t| t.name == 'tabernacle' }
main_group = project.main_group.children.find { |c| c.path == 'tabernacle' || c.name == 'tabernacle' }

unless main_group
  puts "Error: Could not find main group 'tabernacle'"
  exit 1
end

def add_files_to_group(project, target, base_group, dir_path)
  Dir.glob("#{dir_path}/**/*.swift").each do |file_path|
    filename = File.basename(file_path)
    # Skip already existing files
    next if ['ContentView.swift', 'tabernacleApp.swift'].include?(filename)

    relative_path = file_path.sub("#{dir_path}/", '')
    path_components = relative_path.split('/')
    path_components.pop # remove filename

    current_group = base_group
    path_components.each do |dir|
      existing_group = current_group.groups.find { |g| g.path == dir || g.name == dir }
      current_group = existing_group || current_group.new_group(dir, dir)
    end

    # Check if reference already exists
    unless current_group.files.any? { |f| f.path == filename }
      file_ref = current_group.new_file(filename)
      target.source_build_phase.add_file_reference(file_ref)
      puts "Added #{filename} to target."
    end
  end
end

add_files_to_group(project, main_target, main_group, 'tabernacle')

project.save
puts "Successfully added Swift files to Xcode project."
