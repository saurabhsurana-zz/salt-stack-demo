{% for group in pillar['groups'] %}

{{ group }}:
  group.present:
    - gid:
    - system: True

{% endfor %}


{% for user, data in pillar['users'].iteritems() -%}

{{ user }}:
  user.present:
    - name: {{ user }}
    - shell: /bin/bash
    - home: /home/{{ user }}
    - groups:
        {% for group in pillar['users'][user]['groups'] -%}
        - {{ group }}
        {% endfor %}

/home/{{ user }}/.ssh/authorized_keys:
  file.managed:
    - makedirs: True
    - requires:
        - user: {{ user }}
        - file: /home/{{ user }}

set_auth_key:
  cmd.run:
    - name: cp /home/ubuntu/.ssh/authorized_keys /home/{{ user }}/.ssh/authorized_keys
    - mode: 600
    - require:
      - file: /home/{{ user }}/.ssh/authorized_keys

/home/{{ user }}:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - dir_mode: 750
    - file_mode: 640
    - recurse:
        - user
        - group
        - mode

{% endfor %}

{% for user in pillar.get('deleted-users', []) -%}
{{ user }}:
  user.absent:
    - purge: True

{% endfor %}
