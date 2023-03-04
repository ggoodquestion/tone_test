#!/bin/sh
cd /home/jiajusu/slmtk/egs/SLMTK1.0/ && make release-sd ${1} 
cd /home/jiajusu/slmtk/egs/SLMTK1.0/release/ntpu-tts-SLMTK1.0 && make clean-pg-sd ${1} && make clean-ss-sd ${1} 
cd /home/jiajusu/slmtk/egs/SLMTK1.0/release/ntpu-tts-SLMTK1.0 && make pg-sd ${1} && make ss-sd ${1}