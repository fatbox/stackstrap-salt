#
# Avahi SLS module
# 
# Copyright 2014 Evan Borgstrom
#

avahi-daemon:
  pkg:
    - installed

  service:
    - running
    - enable: True
    - require:
      - pkg: avahi-daemon

# vim: set ft=yaml ts=2 sw=2 et sts=2 :
