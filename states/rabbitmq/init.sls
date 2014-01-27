rabbitmq-server:
  pkg.installed:
    - name: rabbitmq-server
  service:
    - running
    - enable: True

{% for rabbit_username, rabbit_password in pillar['rabbit_users_list'].iteritems() -%}

rabbit_user_{{ rabbit_username }}:
  rabbitmq_user.present:
    - name: {{ rabbit_username }}
    - password: {{ rabbit_password }}
    - force: True
    - require:
      - pkg: rabbitmq-server

rabbit_user_permissions_{{ rabbit_username }}:
  rabbitmq_vhost.present:
    - name: /
    - user:  {{ rabbit_username }}

{% endfor %}
