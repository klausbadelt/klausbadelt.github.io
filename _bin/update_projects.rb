#!/usr/bin/env ruby
require 'taglib'
require 'base64'
require 'uri'

SITE_BUCKET = 'klausbadelt-com'.freeze
SITE_URL = 'https://s3.amazonaws.com/' + SITE_BUCKET

MX_URL = 'https://s3.amazonaws.com/klausbadelt-pool'.freeze
# MX_URL = 'http://d1l2jfi73qwuu8.cloudfront.net'
MX_FOLDER = '/Volumes/music/_KBpool/_website'.freeze

print "This script will write all mp3 albums in #{MX_FOLDER} as new posts,
generate the site html and sync it to S3.
Put all mp3s in folders under #{MX_FOLDER} named after the project ID (3 letter code).
Set ID3 tags for album, title, track, release and comment (as Buy URL).
Each album needs a poster sized 300×430px named <project-ID>.jpg
stored in the folder ../images/posters.

Continue (y/n)? "
exit unless gets == "y\n"

# read all projects as subfolders in MX_FOLDER /*
Dir.glob("#{MX_FOLDER}/**").sort.each do |folder|
  project = File.basename(folder)
  print "#{project}: "
  if project[0, 1] == '_'
    puts '[Skipping]'
    next
  end

  # don't overwrite Writing post - test for match with any date (2013-10-03-project.markup)
  unless (match = Dir.glob(File.join('_posts/*')).grep(/\d*-\d*-\d*-#{project}\./)).empty?
    puts "#{project} already exists: #{File.basename(match.first)}. Skipping."
    next
  end

  # get 'global' vars from first mp3
  audiofiles = Dir.glob(File.join(folder, '*.mp3'))
  mp3 = TagLib::FileRef.new audiofiles.first
  abort "Error in #{folder}" if mp3.tag.nil?
  album = mp3.tag.album.gsub(/ \[.*\]/, '').tr(':""', '')
  release = mp3.tag.year ? Time.local(mp3.tag.year) : Time.now
  buy = mp3.tag.comment if mp3.tag.comment =~ /^#{URI::ABS_URI}$/ # check for valid URL
  puts "#{album} (#{release.year})"
  mp3.close

  # write post front matter
  postname = "_posts/#{release.strftime('%Y-%m-%d')}-#{project}.markdown"
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
    post.puts 'tracks:'

    # sort tracks by track #
    tracks = []
    audiofiles.each do |audiofile|
      TagLib::FileRef.open audiofile do |mp|
        tracks << {
          href: Base64.encode64(File.join(MX_URL, project, File.basename(audiofile))).tr("\n", '').chomp,
          title: mp.tag.title.tr(':', ''),
          track: mp.tag.track,
          duration: Time.at(mp.audio_properties.length).utc.strftime('%M:%S')
        }
      end
    end

    tracks = tracks.sort { |x, y| x[:track] <=> y[:track] }

    # write tracklisting
    tracks.each do |track|
      post.puts " - title: #{track[:title]}"
      post.puts "   url: #{track[:href]}"
      post.puts "   duration: #{track[:duration]}"

      # puts "\t#{track[:track]}. #{track[:title]}"
    end
    post.puts '---'
  end
end

# puts 'Syncing music...'
# system "cd .. && s3cmd sync --rr -P --delete-removed #{MX_FOLDER}/ s3://#{MX_BUCKET}"
# puts 'Syncing site...'
# system "cd .. && jekyll build && s3cmd sync --rr -P --delete-removed _site/ s3://#{SITE_BUCKET}"
