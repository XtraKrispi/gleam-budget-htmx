#! /bin/bash
# https://www.howtogeek.com/687970/how-to-run-a-linux-program-at-startup-with-systemd/

sudo cp budget.sh /usr/local/bin

sudo chmod +x /usr/local/bin/budget.sh

# Check to make sure the service name isn't used
# sudo systemctl list-unit-files --type-service

sudo cp budget.service /etc/systemd/system/budget.service
sudo chmod 640 /etc/systemd/system/budget.service

sudo systemctl daemon-reload
sudo systemctl enable budget
sudo systemctl start budget
# Can check status:
# sudo systemctl status budget
# Can stop:
# sudo systemctl stop budget
# Can kill (works better):
# sudo systemctl kill budget
# Can disable:
# sudo systemctl disable budget

