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
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    child.sendline("sudo apt-get install -y python3-pip xvfb")
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    child.sendline("pip3 install paho-mqtt")
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    child.sendline("wget https://raw.githubusercontent.com/mohamed9974/rpi-os-custom-image-with-sensors/main/emulated_senosrs/scripts/simulate.py")
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    child.sendline("wget https://raw.githubusercontent.com/mohamed9974/rpi-os-custom-image-with-sensors/main/startup.sh")
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # add the startup script to the rc.local file
    child.sendline("sudo sed -i 's/exit 0//g' /etc/rc.local")
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    child.sendline("sudo sh -c \"echo 'bash /home/pi/startup.sh &' >> /etc/rc.local \"")
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    child.sendline("sudo sh -c \"echo 'exit 0' >> /etc/rc.local\"")
    child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # enable the cron service to run at every reboot
    # child.sendline("sudo systemctl enable cron")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # # start the cron service
    # child.sendline("sudo systemctl start cron")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # # create a cron file
    # child.sendline("sudo touch /etc/cron.d/mosquitto")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # child.sendline("sudo chmod 777 /etc/cron.d/mosquitto")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # child.sendline("sudo echo '@reboot python3 /home/pi/simulate.py mosquitto' > /etc/cron.d/mosquitto")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # child.sendline("sudo chmod 644 /etc/cron.d/mosquitto")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # child.sendline("sudo systemctl restart cron")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # child.sendline("ls -ahl /etc/cron.d/")
    # # add a cron job to run the python script located in the home directory at every reboot
    # child.sendline("crontab -l | { cat; echo '@reboot python3 /home/pi/simulate.py mosquitto'; } | sudo crontab -")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # child.sendline("crontab -l | { cat; echo '@reboot python3 /home/pi/simulate.py mosquitto'; } | crontab -")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # child.sendline("cat /etc/cron.d/mosquitto")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    # child.sendline("crontab -l")
    # child.expect_exact(customise_os.BASH_PROMPT, timeout=15*60)
    
    
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
