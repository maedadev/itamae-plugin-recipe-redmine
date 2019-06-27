#!/bin/bash

expect -c "
  set timeout 5
  spawn sudo -u postgres LANG=en.en_US createuser -P redmine

  expect \"Enter password for new role\"
  send \"$1\n\"

  expect \"Enter it again\"
  send \"$1\n\"

  interact
"
