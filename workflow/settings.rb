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
  # puts alfred.setting.load
  fb = alfred.feedback
  begin
    if ARGV.length < 2
      show(fb, alfred)
      puts fb.to_xml(ARGV)
    elsif ARGV.length == 2
      setting = ARGV[0]
      if !$default_settings.has_key?(setting)
        raise "Not A Valid Setting"
      end

      fb.add_item({
        :uid      => "" ,
        :title    => "#{setting}",
        :subtitle => "Set to: #{ARGV[1]}",
        :valid    => "yes",
        :arg      => "#{setting} #{ARGV[1]}"
      })

      puts fb.to_xml()
    else
      setting = ARGV[1]
      if !ARGV.first == "set" || !$default_settings.has_key?(setting)
        raise "Invalid Option"
      end

      settings = get_settings(alfred)
      settings[setting] = ARGV[2]
      alfred.setting.dump(settings)

      puts "#{setting} set to #{ARGV[2]}"

    end
  rescue Exception => e
    alfred.with_rescue_feedback = true
    raise Alfred::NoBundleIDError, e.message
  end


end
