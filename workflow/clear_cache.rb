#!/usr/bin/env ruby
# encoding: utf-8
($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require "json"
require "filecache"

Alfred.with_friendly_error do |alfred|
  cache_path = alfred.volatile_storage_path
  caches = ["stacks", "instances"]
  caches.each do |key|
    cache = FileCache.new(key, cache_path)
    cache.clear
  end

  puts "OpsWorks Cache Cleared"
end