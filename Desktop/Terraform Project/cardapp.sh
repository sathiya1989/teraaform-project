#! /bin/bash

sudo apt-get update
sudo apt-get install apache2 -y
sudo git clone git@github.com:amolshete/card-website.git /
sudo rm /var/www/html/index.html
sudo cp -R /card-website/ /var/www/html/
sudo service apache2 restart



# sudo apt-get update
# sudo apt-get install -y apache2
# gitclone git@github.com:amolshete/card-website.git
# cd /var/www/html
# rm index.html
# cp -rf /cardwebsite/* .