#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Dowload and run a Raspberry PI OS image with Docker and QEMU to customise it.
"""
import shutil

import download_os
import customise_os
import customise_os_mu


def main():
    # Download and unzip OS image
    # compressed_path = download_os.download_compressed_image()
    # img_path = download_os.decompress_image(compressed_path)

    # # Create a copy of the original image and configure it with autologin
    # autologin_img = img_path.replace(".img", "-autologin.img")
    # shutil.copyfile(img_path, autologin_img)
    # customise_os.run_edits(
    #     autologin_img, needs_login=True, autologin=True, ssh=False, expand_fs=False
    # )

    # # Create a copy of the original image and configure it autologin + ssh
    # autologin_ssh_img = img_path.replace(".img", "-autologin-ssh.img")
    # shutil.copyfile(img_path, autologin_ssh_img)
    # customise_os.run_edits(
    #     autologin_ssh_img, needs_login=True, autologin=True, ssh=True, expand_fs=False
    # )

    # # Copy original image and configure it autologin + ssh + expanded filesystem
    # autologin_ssh_fs_img = img_path.replace(".img", "-autologin-ssh-expanded.img")
    # shutil.copyfile(img_path, autologin_ssh_fs_img)
    # customise_os.run_edits(
    #    autologin_ssh_fs_img, needs_login=True, autologin=True, ssh=True, expand_fs=True
    # )
    img_path = "./rpiosimage/2022-04-04-raspios-buster-armhf-lite.img"
    autologin_ssh_fs_img = "./rpiosimage/2022-04-04-raspios-buster-armhf-lite-autologin-ssh-expanded.img"
    # Copy expanded image (last one created) and install Mu dependencies
    mu_img = img_path.replace(".img", "-class-mu.img")
    shutil.copyfile(autologin_ssh_fs_img, mu_img)
    customise_os_mu.run_edits(mu_img, needs_login=False)


if __name__ == "__main__":
    main()
