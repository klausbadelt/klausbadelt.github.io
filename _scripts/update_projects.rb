#!/usr/bin/env ruby
require 'taglib'
require 'base64'
require 'uri'

POOL = "https://s3.amazonaws.com/pool.klausbadelt"

puts "This script will write all mp3 albums in ../mx as new posts."
puts "Set ID3 tags for album, title, release and comment (as Buy URL)"
print "Continue (y/n)? "
exit 1 unless gets == "y\n"
puts 'Scanning mp3s...'
# read all projects as subfolders in mx/*
Dir.glob('../mx/**') do |folder|
  project = File.basename(folder)
  
  # don't overwrite existing post - test for match with anyt date (2013-10-03-project.markup)
  # unless (match = Dir.glob(File.join('../_posts/*')).grep(/\d*-\d*-\d*-#{project}\./)).empty?
  #   puts "#{project} already exists: #{File.basename(match.first)}. Skip."
  #   next
  # end
  
  # get global vars from first mp3
  audiofiles = Dir.glob(File.join(folder,'*.mp3'))
  mp3 = TagLib::FileRef.new audiofiles.first
  album = mp3.tag.album.gsub(/ \[.*\]/, '').tr(':""','')
  release = mp3.tag.year ? Time.local(mp3.tag.year) : Time.now
  buy = mp3.tag.comment if mp3.tag.comment =~ /^#{URI::ABS_URI}$/ # check for valid URL
  mp3.close

    
  # write post front matter
  postname = "../_posts/#{release.strftime("%Y-%m-%d")}-#{project}.markdown"
  puts "Writing \"#{album}\""
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

    # write tracklisting
    audiofiles.each do |audiofile|
      TagLib::FileRef.open audiofile do |mp3|
        href = Base64.encode64("#{POOL}/#{project}/#{File.basename(audiofile)}").tr("\n","").chomp
        title = mp3.tag.title.tr(':','')
        duration = Time.at(mp3.audio_properties.length).utc.strftime("%M:%S")
      
        post.puts " - title: #{title}"
        post.puts "   url: #{href}"
        post.puts "   duration: #{duration}"
      end
    end
    post.puts "---"
  end
end

puts 'Uploading site...'
system 'cd .. && jekyll build && s3cmd sync --rr -P --delete-removed _site/ s3://www.klausbadelt.com'
