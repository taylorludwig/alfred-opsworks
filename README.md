Alfred AWS OpsWorks Workflow
----------------------------
![animation](screenshots/animation.gif)

## Requirements
- [AWS CLI](http://aws.amazon.com/cli/)

## Commands
### ops instances
First displays all stacks, after selecting all instances within stack are showing
- <kbd>Enter</kbd>: ssh into instance (uses private IP(VPC) if no external IP exists)
- <kbd>Command</kbd> + <kbd>Enter</kbd>: copy and paste the IP
- <kbd>Shift</kbd> + <kbd>Enter</kbd>: opens the IP in a browser

### ops clear
Clears the cache for forced refresh of data.  Cache is used by default so real time filtering can be used without performing an AWS call on every keystroke

### ops deployments
First displays all stacks, after selecting all deployments for the stack are shown
- <kbd>Enter</kbd>: show deployment json in large text

### ops settings
Options for viewing and changing the settings

- ops settings aws_path: Change the CLI location. Default /usr/local/bin/aws
- ops settings profile: The AWS CLI profile to use. Default default
- ops settings cache_length: Seconds before invaliding cache. Default 3600

## Future Features
- Settings for passing SSH options
- Drill down into instances of deployments
- Re-run a deployment
- Open to OpsWork console for instances and deployments
- ???
