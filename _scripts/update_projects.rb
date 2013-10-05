#!/usr/bin/env ruby
require 'taglib'
require 'htmlentities'
require 'base64'

htmler = HTMLEntities.new

# read all projects as subfolders in mx/*
Dir.glob('../mx/**') do |folder|
  project = File.basename(folder)
  
  # does post of this project already exist? Testing for exact match (2013-10-03-project.markup)
  unless (match = Dir.glob(File.join('../_posts/*')).grep(/\d*-\d*-\d*-#{project}\./)).empty?
    puts "#{project} already exists: #{File.basename(match.first)}. Skip."
    next
  end
  
  # get Project Title from first mp3
  audiofiles = Dir.glob(File.join(folder,'*.mp3'))
  release = Time.now
  album = project
  Mp3Info.open audiofiles.first do |mp3|
    album = mp3.tag.album
    release = Time.local(mp3.tag2.TYER) if mp3.tag2.TYER
    puts mp3.tag.TYER
  end
  album_html = htmler.encode album    # html safe
  album_attr = album_html.tr("'","_") # and additionally attribute safe, i.e. no single quotes
  
  # start writing post with  front matter
  postname = "../_posts/#{release.strftime("%Y-%m-%d")}-#{project}.markdown"
  puts "Writing #{postname}"
  post = File.open(postname, 'w')
  post.write(<<EOS)
---
layout: post
title: #{album}
poster: #{project}.jpg
date: #{release}
categories: film
---
<ol class="tracklisting">
EOS

  # write tracklisting
  audiofiles.each do |audiofile|
    Mp3Info.open audiofile do |mp3|
      href = Base64.encode64("/mx/#{project}/#{File.basename(audiofile)}").chomp
      title = htmler.encode mp3.tag.title
      post.puts "  <li><a href='#{href}' rel='/images/posters/#{project}.jpg' title='#{album_html.tr("'","_")} - #{title.tr("'","_")}'>#{title}</a></li>"
    end
  end
  post.puts "</ol>"
end
