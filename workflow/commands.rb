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
  fb = alfred.feedback
  begin


    commands = get_commands(ARGV.first, alfred)
    #Get all the instanceIds so we can get their names all at once
    instance_ids = Array.new
    commands.each { |command|
      instance_ids << command['InstanceId']
    }
    instances = get_instances(instance_ids, alfred)

    commands.each { |command|
      if instances.has_key?(command["InstanceId"])
        name = instances[command["InstanceId"]]["Hostname"]
      else
        name = "Unknown"
      end


      time = distance_of_time_in_words(DateTime.strptime(command['CreatedAt'], '%Y-%m-%dT%H:%M:%S%z'))


      fb.add_item({
        :uid      => "#{command["CommandId"]}",
        :title    => "#{name}",
        :subtitle => "#{time} ago",
        :arg      => "#{command["CommandId"]}",
        :valid    => "yes",
        :icon     => {:type => "default", :name => get_instance_icon(command["Status"]) }
      })
    }

    if commands.empty?
      fb.add_item({
        :uid      => "" ,
        :title    => "Empty Commands #{ARGV.first}",
        :subtitle => "",
        :valid    => "no",
        :icon     => {:type => "default", :name => get_instance_icon("error") }
      })
    end

    puts fb.to_xml(ARGV[1] || '')



  rescue Exception => e
    alfred.with_rescue_feedback = true
    raise Alfred::NoBundleIDError, e.message
  end


end


