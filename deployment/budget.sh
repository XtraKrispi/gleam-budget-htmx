#!/bin/bash

echo "budget.service: ## Starting ##" | systemd-cat -p info

cd /home/xtrakrispi/webapps/budget
./entrypoint.sh run
