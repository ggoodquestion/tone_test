#!/bin/sh
chmod -R 777 /home/jiajusu/slmtk/egs/SLMTK1.0/${2}/intermediate/
cd /home/jiajusu/slmtk/egs/SLMTK1.0 && make ${1} ${2}
