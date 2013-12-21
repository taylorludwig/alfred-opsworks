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

    stacks = get_stacks alfred
    if !stacks.has_key?(ARGV.first)
      populate_stack_feedback(fb, stacks)
      puts fb.to_xml(ARGV.first || '')

    else
        stack = stacks[ARGV.first]
        deployments = get_deployments(stack["StackId"], alfred)

        deployments.each { |id, deployment|
          name = deployment["Command"]["Name"]
          if name == "execute_recipes"
            name = "#{name}: #{deployment["Command"]["Args"]["recipes"].join(',')}"
          end

          if name == "deploy"
            name = "#{name}: #{get_app_name(deployment["AppId"], alfred)}"
          end

          if deployment.has_key?("IamUserArn")
            match = deployment["IamUserArn"].match('user/(.*)$')
            author = match ? match[1] : "Unknown"
          else
            author = "OpsWorks"
          end

          if deployment.has_key?("Comment")
            author += ": #{deployment["Comment"]}"
          end

          time = distance_of_time_in_words(DateTime.strptime(deployment['CreatedAt'], '%Y-%m-%dT%H:%M:%S%z'))
          instances = deployment["InstanceIds"].size

          fb.add_item({
            :uid      => "#{id}" ,
            :title    => "#{name}",
            :subtitle => "#{time} ago: #{instances} Instances: #{author}",
            :arg      => "#{id}" ,
            :valid    => "yes",
            :icon     => {:type => "default", :name => get_instance_icon(deployment["Status"]) }
          })
        }

        if deployments.empty?
          fb.add_item({
            :uid      => "" ,
            :title    => "Empty Stack #{ARGV.first}",
            :subtitle => "",
            :valid    => "no",
            :icon     => {:type => "default", :name => get_instance_icon("error") }
          })
        end

        puts fb.to_xml(ARGV[1] || '')

    end

  rescue Exception => e
    alfred.with_rescue_feedback = true
    raise Alfred::NoBundleIDError, e.message
  end


end


