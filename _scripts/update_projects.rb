#!/usr/bin/env ruby
require 'taglib'
require 'base64'

# read all projects as subfolders in mx/*
Dir.glob('../mx/**') do |folder|
  project = File.basename(folder)
  
  # don't overwrite existing post - test for exact match (2013-10-03-project.markup)
  # unless (match = Dir.glob(File.join('../_posts/*')).grep(/\d*-\d*-\d*-#{project}\./)).empty?
  #   puts "#{project} already exists: #{File.basename(match.first)}. Skip."
  #   next
  # end
  
  # get global vars like from first mp3
  audiofiles = Dir.glob(File.join(folder,'*.mp3'))
  release = Time.now
  album = project
  TagLib::FileRef.open audiofiles.first do |mp3|
    unless mp3.null?
      album = mp3.tag.album.gsub(/\[.*\]/, '') if mp3.tag.album
      release = Time.local(mp3.tag.year) if mp3.tag.year > 0
    end
  end
  
  # write post front matter
  postname = "../_posts/#{release.strftime("%Y-%m-%d")}-#{project}.markdown"
  puts "Writing #{album}"
  File.open(postname, 'w') do |post|
    post.write(<<eos)
---
layout: post
title: #{album}
poster: #{project}.jpg
date: #{release}
categories: film
tracks:
eos

    # write tracklisting
    audiofiles.each do |audiofile|
      TagLib::FileRef.open audiofile do |mp3|
        href = Base64.encode64("/mx/#{project}/#{File.basename(audiofile)}").chomp
        title = mp3.tag.title
        duration = Time.at(mp3.audio_properties.length).utc.strftime("%M:%S")
      
        post.puts " - title: #{title}"
        post.puts "   url: #{href}"
        post.puts "   duration: #{duration}"
      end
    end
    post.puts "---"
  end
end
