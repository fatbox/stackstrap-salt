#
# Nginx macros
# 
# Copyright 2013 FatBox Inc
#

{% macro nginxsite(domain, user, group,
                   template='standard-server.conf',
                   defaults=None,
                   listen='80',
                   server_name=None,
                   root='public',
                   create_root=True,
                   enabled=True,
                   enabled_name=None,
                   ssl=False,
                   ssl_alias=False,
                   custom=None) -%}

# if ssl_alias is true then we want to setup an identical site with ssl enabled
# as well, you still need to supply ssl_certificate and ssl_certificate_key to
# the defaults
{% if ssl_alias %}
{{ nginxsite(domain, user, group,
          template=template,
          defaults=defaults,
          listen='443',
          server_name=server_name,
          root=root,
          create_root=False,
          enabled=enabled,
          enabled_name=enabled_name,
          ssl=True,
          ssl_alias=False,
          custom=custom) }}
{% endif %}

/home/{{ user }}/domains/{{ domain }}:
  file:
    - directory
    - user: {{ user }}
    - group: {{ group or user }}
    - mode: 755
    - require:
      - user: {{ user }}
      - file: /home/{{ user }}/domains

{% if create_root %}
/home/{{ user }}/domains/{{ domain }}/{{ root }}:
  file:
    - directory
    - user: {{ user }}
    - group: {{ group or user }}
    - mode: 755
    - require:
      - file: /home/{{ user }}/domains/{{ domain }}
{% endif %}

/etc/nginx/sites-available/{{ domain }}.{{ listen }}.conf:
  file:
    - managed
    - require:
      - file: /home/{{ user }}/domains/{{ domain }}
    - user: root
    - group: root
    - mode: 444
    - source: salt://nginx/files/{{ template }}
    - watch_in:
      - service: nginx
    - template: jinja
    - defaults:
        server_name: "{{ server_name or domain }}"
        listen: "{{ listen }}"
        domain: {{ domain }}
        owner: {{ user }}
        group: {{ group }}
        root: {{ root }}
        ssl: {{ ssl }}{% if custom %}
        custom: "sites-available/{{ domain }}.{{ listen }}-custom"{% endif %}{% if defaults %}{% for n in defaults %}
        {{ n }}: "{{ defaults[n] }}"{% endfor %}{% endif %}

{% if custom %}
/etc/nginx/sites-available/{{ domain }}.{{ listen }}-custom:
  file:
    - managed
    - user: root
    - group: root
    - mode: 444
    - source: {{ custom }}
{% endif %}

/etc/nginx/sites-enabled/{{ enabled_name or domain }}.{{ listen }}.conf:
  file:
{% if enabled %}
    - symlink
    - target: /etc/nginx/sites-available/{{ domain }}.{{ listen }}.conf
    - require:
      - file: /etc/nginx/sites-available/{{ domain }}.{{ listen }}.conf
{% else %}
    - absent
{% endif %}
    - watch_in:
      - service: nginx

{% endmacro %}

# vim: set ft=yaml ts=2 sw=2 et sts=2 :
