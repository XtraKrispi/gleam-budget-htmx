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

# https://serverfault.com/questions/413397/how-to-set-environment-variable-in-systemd-service
# systemctl edit budget
# Modify the Environment section to include PATH and BUDGET_SECRET_KEY separately!
#[Service]
#Environment="PATH=PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
#Environment="BUDGET_SECRET_KEY=whatever_you_want"]
