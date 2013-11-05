#
# StackStrap Master SLS
# This state sets up a machine to run the StackStrap master application
# 
# Copyright 2013 FatBox Inc
#

include:
  - uwsgi
  - nginx
  - virtualenv
  - postgres

{% from "utils/users.sls" import skeleton %}
{% from "postgres/macros.sls" import postgres_user_db %}
{% from "nginx/macros.sls" import nginxsite %}
{% from "uwsgi/macros.sls" import uwsgiapp %}

# TODO
python-psycopg2:
  pkg:
    - installed
git:
  pkg:
    - installed


{% set config = grains.get('stackstrap', {}) %}

# set mode so we can use it later
{% set mode = config.get('mode', 'dev') %}

# which nginx template should we use
{% if mode == 'dev' %}
{% set nginx_template = "proxy-django.conf" %}
{% else %}
{% set nginx_template = "uwsgi-django.conf" %}
{% endif %}

{{ skeleton("stackstrap", 6000, 6000) }}
{{ postgres_user_db("stackstrap") }}

# make sure the root user is a member of the saltstack group so that 
# permissive_pki_access will allow us to write to the pki dir
root_in_stackstack_group:
  user:
    - present
    - name: root
    - groups:
      - stackstrap
    - require:
      - group: stackstrap

# set our permissions on /etc/salt/pki
# salt's permission system requires that the top level pki & master
# dirs be 750, but we can make our minions dir 770 so we can write
# to it
stackstrap_salt_dirs_base:
  file:
    - directory
    - group: stackstrap
    - mode: 750
    - require:
      - user: root_in_stackstack_group
    - names:
      - /etc/salt/pki
      - /etc/salt/pki/master

/etc/salt/pki/master/minions:
  file:
    - directory
    - group: stackstrap
    - mode: 770
    - require:
      - file: stackstrap_salt_dirs_base


# setup the directory our project specific sls files will live in
/home/stackstrap/project_states:
  file:
    - directory
    - user: stackstrap
    - group: stackstrap
    - mode: 750
    - require:
      - user: stackstrap

# setup the directory for our project logs
/home/stackstrap/logs:
  file:
    - directory
    - user: stackstrap
    - group: stackstrap
    - mode: 750
    - require:
      - user: stackstrap

# setup an nginx site on the specified config, or use "_" if one doesn't exist
# so that we catch all traffic
#
# TODO: SSL 
{{ nginxsite("stackstrap-master", "stackstrap", "stackstrap",
    server_name=config.get('http_server_name', '_'),
    template=nginx_template,
    root=False,
    create_root=False,
    ssl=config.get('http_ssl', False),
    defaults={
      'listen': config.get('http_listen', '80'),
      'port': 6000,
      'mode': mode,
      'ssl_certificate': config.get('http_ssl_certificate'),
      'ssl_certificate_key': config.get('http_ssl_certificate_key'),
    }
) }}

{% if mode == 'dev' %}
# TODO - run django-admin runserver
{% else %}
{{ uwsgiapp("stackstrap", "stackstrap", "stackstrap", "/home/stackstrap",
            "/home/stackstrap/virtualenv",
            "/home/stackstrap/current/application/stackstrap",
            "127.0.0.1:6000",
            "stackstrap/wsgi.py",
            "DJANGO_SETTINGS_MODULE=stackstrap.settings.%s" % config.get('settings', mode)
) }}
{% endif %}

stackstrap_env:
  virtualenv:
    - managed
    - name: /home/stackstrap/virtualenv
    - requirements: /home/stackstrap/current/application/requirements/{{ config.get('requirements', mode) }}.txt
    - user: stackstrap
    - no_chown: True
    - system_site_packages: True
    - require:
      - user: stackstrap
      - pkg: virtualenv_pkgs

stackstrap_django_dirs:
  file:
    - directory
    - owner: stackstrap
    - group: stackstrap
    - mode: 755
    - require:
      - file: /home/stackstrap/domains/stackstrap-master
    - names:
      - /home/stackstrap/domains/stackstrap-master/static
      - /home/stackstrap/domains/stackstrap-master/media

# vim: set ft=yaml ts=2 sw=2 et sts=2 :
