#
# PostgreSQL SLS file
# Install and manage PostgreSQL
# 
# Copyright 2014 Evan Borgstrom
#

postgres:
  pkg:
    - installed
    - name: {{ pillar['pkg']['postgres'] }}

  service:
    - running
    - name: {{ pillar['svc']['postgres'] }}
    - require:
      - pkg: postgres
  
# vim: set ft=yaml ts=2 sw=2 et sts=2 :
