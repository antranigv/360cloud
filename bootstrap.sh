#!/bin/sh

mkdir ~/.360cloud/
cd ~/.360cloud/

fetch https://raw.githubusercontent.com/antranigv/360cloud/main/config.sh.sample
fetch https://raw.githubusercontent.com/antranigv/360cloud/main/init.sh

cp config.sh.sample config.sh
$EDITOR config.sh

source config.sh

./init.sh
