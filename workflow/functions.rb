$default_settings = {
  'aws_path'     => '/usr/local/bin/aws',
  'profile'      => 'default',
  'cache_length' => 3600
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

def get_stacks(alfred)
  settings = get_settings(alfred)
  cache = FileCache.new("stacks", alfred.volatile_storage_path, settings["cache_length"])
  cached_stacks = cache.get("#{settings["profile"]}")
  if !cached_stacks
    res = `#{settings["aws_path"]} opsworks describe-stacks --profile #{settings["profile"]} 2>&1`
    if !valid_json? res
      raise res
    end

    stacks = JSON.parse(res)
    indexed_stacks = Hash.new
    stacks["Stacks"].each { |stack|
      indexed_stacks[stack["Name"].tr(' ', '-')] = stack
    }

    cache.set("#{settings["profile"]}", indexed_stacks)
  else
    indexed_stacks = cached_stacks
  end

  indexed_stacks
end

def get_intances(stack_id, alfred)
  settings = get_settings(alfred)
  cache = FileCache.new("instances", alfred.volatile_storage_path, settings["cache_length"])
  cached_instances = cache.get(stack_id)
  if !cached_instances
    res = `#{settings["aws_path"]} opsworks describe-instances --stack-id #{stack_id} --profile #{settings["profile"]} 2>&1`
    if !valid_json? res
      raise res
    end

    instances = JSON.parse(res)
    indexed_instances = Hash.new
    instances["Instances"].each { |instance|
      indexed_instances["#{instance["Hostname"]}"] = instance
    }

    cache.set(stack_id, indexed_instances)
  else
    indexed_instances = cached_instances
  end

  indexed_instances
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
  when "online"
    return "icons/online.png"
  when "launcing"
    return "icons/launching.png"
  when "shutting_down"
    return "icons/shutting_down.png"
  when "stopped"
    return "icons/stopped.png"
  when "error"
    return "icons/error.png"
  else
    return "icons/error.png"
  end

end