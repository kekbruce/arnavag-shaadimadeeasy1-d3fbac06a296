#!/bin/env ruby
# encoding: utf-8
#
namespace :onetime do
  desc 'Arnav : Usage -> rake RAILS_ENV=development onetime:populate_categories'
  task :populate_categories => :environment do

    activities = ['Photographer', 'Videographers', 'Location', 'Make-up', 'Decoration', 'Catering', 'Transportation Services', 'DJs',
                 'Jewelry', 'Dress & Apparels', 'Wedding Planner', 'Invitation Cards', 'Night Stay']

    activities.each do |type|
      Category.create!(:type => type) rescue next
    end

  end
end