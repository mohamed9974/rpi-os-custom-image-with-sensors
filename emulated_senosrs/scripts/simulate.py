import random
import json
import socket
import time
import datetime
import paho.mqtt.client as mqtt
import sys
# MQTT broker information
# Set the server IP from argument passed to the script
server_ip = sys.argv[1]
MQTT_BROKER = server_ip
MQTT_PORT = 1883
# get the machine name from the system not from the user
machine_name = socket.gethostname()
# MQTT topic
MQTT_TOPIC = "/sensors"

# Create MQTT client
client = mqtt.Client()

# Connect to MQTT broker
client.connect(MQTT_BROKER, MQTT_PORT)

def generate_temperature(occupancy, time_of_day, CO2):
  if CO2 < 400:
    if occupancy == 0:
      if time_of_day == "day":
        return random.uniform(18, 23)
      else:
        return random.uniform(15, 23)
    else:
      if time_of_day == "day":
        return random.uniform(23, 28)
      else:
        return random.uniform(20, 28)
  else:
    if occupancy == 0:
      if time_of_day == "day":
        return random.uniform(20, 23)
      else:
        return random.uniform(18, 23)
    else:
      if time_of_day == "day":
        return random.uniform(23, 26)
      else:
        return random.uniform(23, 28)


def generate_humidity(occupancy, time_of_day, temperature):
  if temperature < 20:
    if occupancy == 0:
      if time_of_day == "day":
        return random.uniform(40, 45)
      else:
        return random.uniform(35, 45)
    else:
      if time_of_day == "day":
        return random.uniform(45, 50)
      else:
        return random.uniform(45, 55)
  else:
    if occupancy == 0:
      if time_of_day == "day":
        return random.uniform(30, 35)
      else:
        return random.uniform(25, 35)
    else:
      if time_of_day == "day":
        return random.uniform(35, 40)
      else:
        return random.uniform(35, 45)


def generate_humidity_ratio(temperature, humidity, pressure):
  temperature_C = temperature
  humidity_ratio = (humidity / 100) * (6.11 * 10 ** ((7.5 * temperature_C) / (237.3 + temperature_C))) / (pressure / 100)
  specific_humidity = humidity_ratio / (1 + humidity_ratio)
  return specific_humidity

def generate_light(occupancy):
  if occupancy:
    return random.uniform(300, 500)
  else:
    return random.uniform(0, 100)

def generate_CO2(occupancy):
  if occupancy:
    return random.uniform(400, 1000)
  else:
    return random.uniform(300, 400)

def generate_occupancy(count):
  if count < 10:
    # Occupied for first 10 readings
    return 1
  elif count < 20:
    # Unoccupied for next 10 readings
    return 0
  else:
    count = count % 20
    if count < 10:
      # Occupied for next 10 readings
      return 1
    else:
        return 0
count = 0
while True:
    # Generate readings
    occupancy = generate_occupancy(count)
    temperature = generate_temperature( occupancy, datetime, generate_CO2(generate_occupancy(count)))
    humidity = generate_humidity(occupancy, datetime, temperature)
    humidity_ratio = generate_humidity_ratio(temperature, humidity, 1013.25)
    light = generate_light(occupancy)
    CO2 = generate_CO2(occupancy)

    readings = {
        "temperature": temperature,
        "humidity": humidity,
        "light": light,
        "CO2": CO2,
        "humidity_ratio": humidity_ratio,
        "occupancy": occupancy
    }
 # send readings to MQTT broker and check if it was successful
    if client.publish(MQTT_TOPIC, json.dumps(readings)):
        print("Readings sent successfully")
    else:
        print("Error sending readings")
    time.sleep(5)
  # Increment counter
    count += 1