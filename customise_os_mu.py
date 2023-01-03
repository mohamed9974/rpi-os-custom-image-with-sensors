#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Run a Raspberry PI OS image with Docker to install Mu Editor specific
apt packages.
"""
import sys

import pexpect

import customise_os


def install_mu_apt_dependencies(child):
    child.sendline("df -h")
    child.expect_exact(customise_os.BASH_PROMPT)
    child.sendline("sudo apt-get update -qq")
    child.expect_exact(customise_os.BASH_PROMPT)
    child.sendline("sudo apt-get install -y xvfb")
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    child.sendline("sudo apt-get install -y git python3-pip")
    child.expect_exact(customise_os.BASH_PROMPT)
    child.sendline("pip3 install paho-mqtt")
    child.expect_exact(customise_os.BASH_PROMPT)
    


def run_edits(img_path, needs_login=True):
    print("Staring Raspberry Pi OS Mu customisation: {}".format(img_path))

    try:
        child, docker_container_name = customise_os.launch_docker_spawn(img_path)
        if needs_login:
            customise_os.login(child)
        else:
            child.expect_exact(customise_os.BASH_PROMPT)
        install_mu_apt_dependencies(child)
        # We are done, let's exit
        child.sendline("sudo shutdown now")
        child.expect(pexpect.EOF)
        child.wait()
    # Let ay exceptions bubble up, but ensure clean-up is run
    finally:
        customise_os.close_container(child, docker_container_name)


if __name__ == "__main__":
    # We only use the first argument to receive a path to the .img file
    run_edits(sys.argv[1])
