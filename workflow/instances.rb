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
      stacks.each { |name, stack|

        fb.add_item({
          :uid      => "#{stack["StackId"]}" ,
          :title    => "#{name}",
          :subtitle => "OpsWorks Stack #{name}",
          :arg      => "#{name}" ,
          :valid    => "no",
          :autocomplete => "#{name} ",
          :icon     => {:type => "default", :name => get_stack_icon(stack["Attributes"]["Color"]) }
        })
      }

      puts fb.to_xml(ARGV.first || '')
    else
        stack = stacks[ARGV.first]
        instances = get_intances(stack["StackId"], alfred)

        instances.each { |name, instance|
          ip = instance.has_key?("PublicIp") ? instance["PublicIp"] : instance["PrivateIp"]
          stopped = instance["Status"] == "stopped"
          fb.add_item({
            :uid      => "#{instance["InstanceId"]}" ,
            :title    => "#{name}",
            :subtitle => "#{ip} #{instance["Status"]} #{instance["InstanceType"]} #{instance["AvailabilityZone"]}",
            :arg      => "#{ip}" ,
            :valid    => stopped ? "no" : "yes",
            :autocomplete => ARGV.first,
            :icon     => {:type => "default", :name => get_instance_icon(instance["Status"]) }
          })
        }

        if instances.empty?
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


