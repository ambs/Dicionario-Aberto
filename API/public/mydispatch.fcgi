#!/bin/bash

export PATH=/opt/perl-5.20.1/bin/
export HOME=/home/ambs
cd /home/ambs/DicionarioAberto/api; p5stack perl public/dispatch.fcgi
