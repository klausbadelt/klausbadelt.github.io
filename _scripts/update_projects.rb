#!/usr/bin/env ruby
require 'taglib'
require 'base64'
require 'uri'

POOL = "https://s3.amazonaws.com/klausbadelt-pool"

puts "This script will write all mp3 albums in ../_website as new posts."
puts "Set ID3 tags for album, title, release and comment (as Buy URL)"
print "Continue (y/n)? "
exit unless gets == "y\n"
# read all projects as subfolders in _website/*
Dir.glob('../_website/**') do |folder|
  project = File.basename(folder)
  print "#{project}: "
  if project[0,1] == '_'
    puts "[Skipping]"
    next
  end
  
  # don't overwrite Writing post - test for match with anyt date (2013-10-03-project.markup)
  # unless (match = Dir.glob(File.join('../_posts/*')).grep(/\d*-\d*-\d*-#{project}\./)).empty?
  #   puts "#{project} already exists: #{File.basename(match.first)}. Skip."
  #   next
  # end
  
  # get global vars from first mp3
  audiofiles = Dir.glob(File.join(folder,'*.mp3'))
  mp3 = TagLib::FileRef.new audiofiles.first
  abort "Error in #{folder}" if mp3.tag.nil?
  album = mp3.tag.album.gsub(/ \[.*\]/, '').tr(':""','')
  puts album
  release = mp3.tag.year ? Time.local(mp3.tag.year) : Time.now
  buy = mp3.tag.comment if mp3.tag.comment =~ /^#{URI::ABS_URI}$/ # check for valid URL
  mp3.close

  
  # write post front matter
  postname = "../_posts/#{release.strftime("%Y-%m-%d")}-#{project}.markdown"
  File.open(postname, 'w') do |post|
    post.write(<<eos)
---
layout: post
title: "#{album}"
poster: #{project}.jpg
date: #{release}
categories: film
eos

    post.puts "buy: #{buy}" if buy
    post.puts "tracks:"

    # sort tracks by track #
    tracks = Array.new
    audiofiles.each do |audiofile|
      TagLib::FileRef.open audiofile do |mp3|
        tracks << {
          href: Base64.encode64("#{POOL}/#{project}/#{File.basename(audiofile)}").tr("\n","").chomp,
          title: mp3.tag.title.tr(':',''), 
          duration: Time.at(mp3.audio_properties.length).utc.strftime("%M:%S")
        }
      end
    end
    tracks = tracks.sort {|x,y| x[:title] <=> y[:title]}
    
    # write tracklisting
    tracks.each do |track|
      post.puts " - title: #{track[:title]}"
      post.puts "   url: #{track[:href]}"
      post.puts "   duration: #{track[:duration]}"
    end
    post.puts "---"
  end
end
