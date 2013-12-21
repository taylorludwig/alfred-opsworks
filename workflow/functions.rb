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
  JSON.pretty_generate(run_command(alfred, "describe-deployments", nil, deployment_id))
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
  when "launcing", "pending", "booting", "running_setup"
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