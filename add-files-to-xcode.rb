#!/usr/bin/env ruby
# ForgeIQ - Add all Swift files to Xcode project automatically
# Usage: ruby add-files-to-xcode.rb

require 'xcodeproj'

project_path = 'ForgeIQ.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Files to add (relative to ForgeIQ/ directory)
files_to_add = [
  'App/AppEnvironment.swift',
  'Core/Audio/AudioRecordingManager.swift',
  'Core/Speech/SpeechTranscriptionManager.swift',
  'Core/Translation/TranslationManager.swift',
  'Modules/VoiceCore/ViewModels/FilesViewModel.swift',
  'Modules/VoiceCore/ViewModels/HomeViewModel.swift',
  'Modules/VoiceCore/Views/FilesTabView.swift',
  'Modules/VoiceCore/Views/HomeView.swift',
  'Modules/VoiceCore/Views/TranscriptDetailView.swift',
  'Modules/VoiceCore/Views/TranscriptView.swift',
  'Shared/Components/LanguageSelectorView.swift',
  'Shared/Components/WaveformView.swift',
  'Shared/Constants.swift',
  'Shared/Models/Recording.swift',
  'Shared/Models/Transcript.swift',
  'Shared/Models/User.swift'
]

# Get main ForgeIQ group
main_group = project.main_group['ForgeIQ']

files_to_add.each do |file_path|
  full_path = "ForgeIQ/#{file_path}"

  # Check if file already exists in project
  existing = project.files.find { |f| f.path == full_path || f.path == file_path }
  next if existing

  # Add file reference
  file_ref = main_group.new_file(full_path)

  # Add to target's build phase
  target.add_file_references([file_ref])

  puts "✅ Added: #{file_path}"
end

project.save
puts "\n✅ All files added to Xcode project"
