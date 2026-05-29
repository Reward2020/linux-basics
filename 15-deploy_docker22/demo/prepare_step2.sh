#!/bin/bash
APP_DIR=$1
echo "!!! Налаштування директорії $APP_DIR..."
sudo mkdir -p "$APP_DIR"
sudo chown -R goit:goit "$APP_DIR" # потрібно виправити на вашого користувача з групою 
