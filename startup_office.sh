# run the startup script
#!/bin/bash 

# run the python script as user pi
sudo su - pi -c "nohup python3 /home/pi/simulate_office.py mosquitto &"