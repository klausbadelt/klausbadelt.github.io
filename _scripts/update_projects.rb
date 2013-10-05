#!/usr/bin/env ruby
require 'taglib'
require 'htmlentities'
require 'base64'

htmler = HTMLEntities.new

# read all projects as subfolders in mx/*
Dir.glob('../mx/**') do |folder|
  project = File.basename(folder)
  
  # does post of this project already exist? Testing for exact match (2013-10-03-project.markup)
  # unless (match = Dir.glob(File.join('../_posts/*')).grep(/\d*-\d*-\d*-#{project}\./)).empty?
  #   puts "#{project} already exists: #{File.basename(match.first)}. Skip."
  #   next
  # end
  
  # get Project Title from first mp3
  audiofiles = Dir.glob(File.join(folder,'*.mp3'))
  release = Time.now
  album = project
  TagLib::FileRef.open audiofiles.first do |mp3|
    unless mp3.null?
      album = mp3.tag.album.gsub(/\[.*\]/, '') if mp3.tag.album
      release = Time.local(mp3.tag.year) if mp3.tag.year > 0
    end
  end
  album_html = htmler.encode album    # html safe
  album_attr = album_html.tr("'","_") # and additionally attribute safe, i.e. no single quotes
  
  # start writing post with  front matter
  postname = "../_posts/#{release.strftime("%Y-%m-%d")}-#{project}.markdown"
  puts "Writing #{album}"
  post = File.open(postname, 'w')
  post.puts "---", "layout: post", "title: #{album}", "poster: #{project}.jpg", "date: #{release}",
    "categories: film","---","<table class='tracklisting table table-condensed'>" #,
    # "<thead><tr>",
    # "<th><a href='#' data-playlist='#{project}' data-enqueue='no' class='fap-add-playlist'>Play All</th>",
    # "</tr></thead><tbody id='#{project}'>"

  # write tracklisting
  audiofiles.each do |audiofile|
    TagLib::FileRef.open audiofile do |mp3|
      href = Base64.encode64("/mx/#{project}/#{File.basename(audiofile)}").chomp
      title = htmler.encode mp3.tag.title
      duration = Time.at(mp3.audio_properties.length).utc.strftime("%M:%S")
      
      post.puts "<tr>"
#      post.puts "<td class='control'><a class='btn btn-default btn-sm' href='#{href}' rel='/images/posters/#{project}.jpg' title='#{album_html.tr("'","_")} - #{title.tr("'","_")}'><span class='track-btn track-play glyphicon glyphicon-play'></a></td>"
      post.puts "<td class='track-title'><a href='#{href}' rel='/images/posters/#{project}.jpg' title='#{album_html.tr("'","_")} - #{title.tr("'","_")}' class='fap-single-track'>#{title}</a></td>"
      post.puts "<td class='track-duration'><small class='text-muted'>#{duration}</small></td>"
      post.puts "<td class='control'> <a href='#{href}' rel='/images/posters/#{project}.jpg' title='#{album_html.tr("'","_")} - #{title.tr("'","_")}' class='fap-single-track control' data-enqueue='yes'><span class='glyphicon glyphicon-plus'></a></td>"
      post.puts "</tr>"
      
    end
  end
  post.puts "</tbody></table>"
end
