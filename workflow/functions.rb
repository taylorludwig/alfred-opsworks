$default_settings = {
  'aws_path'     => '/usr/local/bin/aws',
  'profile'      => 'default',
  'cache_length' => 30
}

def get_settings(alfred)
  $default_settings.merge(alfred.setting.load)
end

def show(fb, alfred)
  settings = get_settings(alfred)

  settings.each do |key, value|
    next if "#{key}" == "id"

    fb.add_item({
        :uid      => "" ,
        :title    => "#{key}",
        :subtitle => "#{value}",
        :valid    => "no",
        :autocomplete => "#{key} ",
      })
  end
end

def valid_json? json_
  JSON.parse(json_)
  return true
rescue JSON::ParserError
  return false
end

def run_command(alfred, command, stack_id=nil, deployment_id=nil)
  settings = get_settings(alfred)
  cache = FileCache.new("#{command}-#{stack_id}-#{deployment_id}", alfred.volatile_storage_path, Integer(settings["cache_length"]))
  cached_res = cache.get("#{settings["profile"]}")
  if !cached_res
    stack_arg = stack_id ? "--stack-id #{stack_id}" : ""
    deployment_arg = deployment_id ? "--deployment-ids #{deployment_id}" : ""
    res = `#{settings["aws_path"]} opsworks #{command} #{stack_arg} #{deployment_arg} --profile #{settings["profile"]} 2>&1`
    if !valid_json? res
      raise res
    end

    res = JSON.parse(res)

    cache.set("#{settings["profile"]}", res)
  else
    res = cached_res
  end

  res
end

def get_stacks(alfred)
  stacks = run_command(alfred, "describe-stacks")
  res = Hash.new
  stacks["Stacks"].each { |stack|
    res[stack["Name"].tr(' ', '-')] = stack
  }

  res
end

def populate_stack_feedback(fb, stacks)
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

end

def get_intances(stack_id, alfred)
  instances = run_command(alfred, "describe-instances", stack_id)
  res = Hash.new
  instances["Instances"].each { |instance|
    res["#{instance["Hostname"]}"] = instance
  }

  res
end

def get_deployments(stack_id, alfred)
  deployments = run_command(alfred, "describe-deployments", stack_id)
  res = Hash.new
  deployments["Deployments"].each { |deployment|
    res["#{deployment["DeploymentId"]}"] = deployment
  }

  res
end

def get_deployment(deployment_id, alfred)
  deployment = run_command(alfred, "describe-deployments", nil, deployment_id)
  JSON.pretty_generate(deployment['Deployments'][0])
end

def get_stack_icon(color)

  case color
  when "rgb(135, 61, 98)"
    return "icons/color1.png"
  when "rgb(111, 86, 163)"
    return "icons/color2.png"
  when "rgb(45, 114, 184)"
    return "icons/color3.png"
  when "rgb(38, 146, 168)"
    return "icons/color4.png"
  when "rgb(57, 131, 94)"
    return "icons/color5.png"
  when "rgb(100, 131, 57)"
    return "icons/color6.png"
  when "rgb(184, 133, 46)"
    return "icons/color7.png"
  when "rgb(209, 105, 41)"
    return "icons/color8.png"
  when "rgb(186, 65, 50)"
    return "icons/color9.png"
  else
    return "color3.png"
  end

end

def get_instance_icon(status)

  case status
  when "online", "successful"
    return "icons/online.png"
  when "launcing", "pending", "booting", "running_setup", "running"
    return "icons/launching.png"
  when "shutting_down", "terminating"
    return "icons/shutting_down.png"
  when "stopped"
    return "icons/stopped.png"
  when "error"
    return "icons/error.png"
  else
    return "icons/error.png"
  end

end

def distance_of_time_in_words(from_time, to_time = Time.now, include_seconds = true)

  from_time = from_time.to_time if from_time.respond_to?(:to_time)
  to_time = to_time.to_time if to_time.respond_to?(:to_time)
  distance = (to_time.to_f - from_time.to_f).abs
  distance_in_minutes = (distance / 60.0).round
  distance_in_seconds = distance.round


  case distance_in_minutes
    when 0..1
      return distance_in_minutes == 0 ?
             "Less than 1 minute" : "#{distance_in_minutes} minutes" unless include_seconds

      case distance_in_seconds
        when 0..4   then "Less than 5 seconds"
        when 5..9   then "Less than 10 seconds"
        when 10..19 then "Less than 20 seconds"
        when 20..39 then "Half a minute"
        when 40..59 then "Less than 1 minute"
        else             "1 minute"
      end

    when 2..44           then "#{distance_in_minutes} minutes"
    when 45..89          then "About 1 hour"
    when 90..1439        then "About #{(distance_in_minutes.to_f / 60.0).round} hours"
    when 1440..2519      then "1 day"
    when 2520..43199     then "#{(distance_in_minutes.to_f / 1440.0).round} days"
    when 43200..86399    then "About 1 month"
    when 86400..525599   then "#{(distance_in_minutes.to_f / 43200.0).round} months"
    else
      fyear = from_time.year
      fyear += 1 if from_time.month >= 3
      tyear = to_time.year
      tyear -= 1 if to_time.month < 3
      leap_years = (fyear > tyear) ? 0 : (fyear..tyear).count{|x| Date.leap?(x)}
      minute_offset_for_leap_year = leap_years * 1440
      # Discount the leap year days when calculating year distance.
      # e.g. if there are 20 leap year days between 2 dates having the same day
      # and month then the based on 365 days calculation
      # the distance in years will come out to over 80 years when in written
      # english it would read better as about 80 years.
      minutes_with_offset         = distance_in_minutes - minute_offset_for_leap_year
      remainder                   = (minutes_with_offset % 525600)
      distance_in_years           = (minutes_with_offset / 525600)
      if remainder < 131400
        "About #{distance_in_years} years"
      elsif remainder < 394200
        "Over #{distance_in_years} years"
      else
        "Almost #{distance_in_years + 1} years"
      end

  end
end