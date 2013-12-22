#!/usr/bin/env ruby
# encoding: utf-8
($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require "json"
require "filecache"
require "functions.rb"

Alfred.with_friendly_error do |alfred|
  begin
    command = get_command(ARGV.first, alfred)
    puts command['Commands'][0]['LogUrl']
  rescue Exception => e
    puts e.message
  end
end