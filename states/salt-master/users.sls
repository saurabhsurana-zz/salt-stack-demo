# Copyright 2014 Hewlett-Packard Development Company, L.P.
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#

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
