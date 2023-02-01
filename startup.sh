# run the startup script
#!/bin/bash 

# run the python script as user pi
sudo -u pi
nohup python3 /home/pi/simulate.py mosquitto &