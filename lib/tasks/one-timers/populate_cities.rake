#!/bin/env ruby
# encoding: utf-8
#
namespace :onetime do
  desc "Arnav : Usage -> rake RAILS_ENV=development onetime:populate_cities"
  task :populate_cities => :environment do

    city_list = ['Delhi', 'Gurgaon', 'Noida', 'Pune', 'Bangalore', 'Mumbai', 'Hyderabad', 'Chennai', 'Kolkata']

    city_list.each do |city|
      City.create!(:city => city) rescue next
    end

  end
end