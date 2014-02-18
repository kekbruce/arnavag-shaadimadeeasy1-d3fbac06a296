#!/bin/env ruby
# encoding: utf-8
#
namespace :onetime do
  desc 'Arnav : Usage -> rake RAILS_ENV=development onetime:populate_shaadi_types'
  task :populate_categories => :environment do

    type_theme = {1 => ['Punjabi', 'Marathi', 'Marwadi', 'South Indian']}

    type_theme.each do |name|
      ShaadiType.create!(:name => name) rescue next
    end

  end
end