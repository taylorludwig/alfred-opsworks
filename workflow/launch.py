#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# jmjeong, 2013/3/25

import os
import plistlib
import subprocess

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

launchArgs = "tell application \"Alfred 2\" to search \"%s\"" % sys.argv[1]
subprocess.check_call(["osascript", "-e", launchArgs])
