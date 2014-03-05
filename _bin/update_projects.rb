#!/usr/bin/env ruby
require 'taglib'
require 'base64'
require 'uri'

SITE_URL = 'https://s3.amazonaws.com/klausbadelt-com'
MX_FOLDER = 'mx'

print "This script will write all mp3 albums in ../#{MX_FOLDER} as new posts,
generate the site html and sync it to S3.
Put all mp3s in folders under ../#{MX_FOLDER} named after the project ID (3 letter code).
Set ID3 tags for album, title, release and comment (as Buy URL).
Each album needs a poster sized 300×430px named <project-ID>.jpg
stored in the folder ../images/posters.

Continue (y/n)? "
exit unless gets == "y\n"

# read all projects as subfolders in MX_FOLDER /*
Dir.glob("../#{MX_FOLDER}/**") do |folder|
  project = File.basename(folder)
  print "#{project}: "
  if project[0,1] == '_'
    puts "[Skipping]"
    next
  end
  
  # don't overwrite Writing post - test for match with any date (2013-10-03-project.markup)
  unless (match = Dir.glob(File.join('../_posts/*')).grep(/\d*-\d*-\d*-#{project}\./)).empty?
    puts "#{project} already exists: #{File.basename(match.first)}. Skipping."
    next
  end
  
  # get 'global' vars from first mp3
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
          href: Base64.encode64("#{SITE_URL}/#{MX_FOLDER}/#{project}/#{File.basename(audiofile)}").tr("\n","").chomp,
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
