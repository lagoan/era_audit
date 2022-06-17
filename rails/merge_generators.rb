#!/usr/bin/env ruby
# frozen_string_literal: true

report_generators = Dir.glob('./generate_report_*')

File.open('all_report_generators.rb', 'w') do |file|
  report_generators.each do |report_generator|
    File.open(report_generator) do |generator_code|
      file << generator_code.read
    end
  end
end
