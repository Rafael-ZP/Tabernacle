require 'xcodeproj'

project_path = 'tabernacle.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
main_target = project.targets.find { |t| t.name == 'tabernacle' }

# Create a reference to the dataset folder
dataset_path = 'Datasets/Bible-niv-main'
file_ref = project.main_group.new_reference(dataset_path)

# We want it to be a folder reference (added as a blue folder in Xcode)
file_ref.last_known_file_type = 'folder'

# Add it to the Copy Bundle Resources build phase
main_target.add_resources([file_ref])

project.save
puts "Successfully added Datasets/Bible-niv-main to the Xcode project."
