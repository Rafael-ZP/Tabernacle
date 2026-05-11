require 'xcodeproj'

project_path = 'tabernacle.xcodeproj'
project = Xcodeproj::Project.open(project_path)
main_target = project.targets.find { |t| t.name == 'tabernacle' }

['Datasets/Bible-kjv-master', 'Datasets/Bible-tamil-main'].each do |dataset_path|
  file_ref = project.main_group.new_reference(dataset_path)
  file_ref.last_known_file_type = 'folder'
  main_target.add_resources([file_ref])
end

project.save
puts "Successfully added Datasets to the Xcode project."
