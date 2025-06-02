# Standalone Application

The standalone application allows you to connect up to 8 RTSP and USB cameras and process
them using an object detection model running on a Hailo chip. The app also includes
a live view for seeing the analytics, event trigger creation, and an event viewer.

## Hardware Requirements

- Hailo8 or Hailo8L chip (driver version 4.21.0 instaleld below).

## Setup for x86

Run `./src/setup/x86-setup.sh` to install the necessary dependencies.

## Setup for Raspberry Pi

A setup script for the Pi is provided at `./src/setup/pi5-setup.sh`. Run this script to
install all the system dependencies. Reboot the system after runnig this script.

## Running

From this directory, run:

```
docker compose up
```

Once the application is running, go to `localhost:8082` in your browser and follow
the first time setup of creating a username and password. Then, you're free to use
the application!
