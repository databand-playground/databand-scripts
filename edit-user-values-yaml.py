import os
try:
    import yaml
except:
    os.system('pip install pyyaml')
    import yaml

import sys

image_repo = sys.argv[1]
image_registry_route = sys.argv[2]
cluster_username = sys.argv[3]
token = sys.argv[4]
fernet = sys.argv[5]
web_server_key = sys.argv[6]

with open("user-values.yaml") as f:
     list_doc = yaml.safe_load(f)

list_doc['global']['databand']['image']['repository'] = image_repo[:-1]
list_doc['global']['databand']['imageCredentials']['registry'] = image_registry_route
list_doc['global']['databand']['imageCredentials']['username'] = cluster_username
list_doc['global']['databand']['imageCredentials']['password'] = token
list_doc['databand']['fernetKey'] = fernet
list_doc['web']['secret_key'] = web_server_key
with open("user-values.yaml", "w") as f:
    yaml.dump(list_doc, f)

print("Updated user-values.yml!")