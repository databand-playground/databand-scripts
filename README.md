# databand


## Install databand in OCP using ocp_install.sh

* **Prerequisites**. 
- Reserve an OCP cluster on Tech Zone: https://techzone.ibm.com/my/reservations/create/63dba359cc19150018af084f
- Docker installed and running on your computer
- Helm installed on your computer, if not you can install usng the following:

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
* oc command line tool installed on your computer and in $PATH. oc can be downloaded from the OCP console of your ROKS cluster, and move oc to one of your paths:

```
echo  $PATH
scp oc /Library/Frameworks/Python.framework/Versions/3.10/bin/oc
```
* Python installed on your computer: Python 3.9 recommended.
* pip installed on your computer, if not, you can install by the following:
```
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
```

## Install steps:

1. Download databand install files: 
<img width="1055" alt="image" src="https://media.github.ibm.com/user/51730/files/5b11c2bf-9d9b-4939-b164-028ea96f3e8f">

2. Unzip the downloaded file `databand-1.0.17-helm-chart.tar.gz` and inside the unzipped folder, unzip the `databand-1.0.17-2.tgz` file to get the databand folder
<img width="781" alt="image" src="https://media.github.ibm.com/user/51730/files/a0ef1770-f8bd-4ac7-bd88-5e784845aa7b">

3. databand folder will be our **working directory**
```
cd databand-1.0.17-helm-chart/databand
```

4. Download [ocp_insall.sh](https://github.ibm.com/Catherine-Cao/databand/blob/main/edit-user-values-yaml.py) and [edit-user-values-yaml.py](https://github.ibm.com/Catherine-Cao/databand/blob/main/ocp_install.sh) into this working direcotry
<img width="767" alt="image" src="https://media.github.ibm.com/user/51730/files/bc31a465-bf15-4534-a257-d033a4685b0c">

5. Open ocp_install.sh with a text editor: <br>

5.1 replace 'oc login' with your credentials which can be copied from your OCP console.

5.2 project_name:it can be anything without any special characters, for example databand <br>

> a lowercase RFC 1123 label must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character

5.3 tar_file_name: it can be found in parent folder of databand, in our case it is `databand-v1.0.17.2-images.tar`: <br>
<img width="374" alt="image" src="https://media.github.ibm.com/user/51730/files/07ed567d-1ca9-4ea6-b225-af9cbbae3530">. 

5.4 cluster_username: can be found in the Tech Zone reservation details page <br>
<img width="1507" alt="image" src="https://media.github.ibm.com/user/51730/files/f36bc8f5-de46-4e38-a7e7-590904921fd0">

Save the changes. 

6. Run the script, in the terminal, run the following command:
```
sh ocp_install.sh
```

7. It will ask you to provide image registry host url, just copy the host url and paste it in the terminal, press enter.
 <img width="1108" alt="image" src="https://media.github.ibm.com/user/51730/files/70ae6bab-a751-48e9-be5c-e4e959daafeb">

8. Wait untill the script finishes running. You should see the following when the install is successful: <br>
<img width="1141" alt="image" src="https://media.github.ibm.com/user/51730/files/154cfd9e-ad98-4510-b638-086d42725ea2">

9. Check all pods running in the terminal or openshift console:
```
oc get pods
```
<img width="570" alt="image" src="https://media.github.ibm.com/user/51730/files/e49ffd5c-a307-4fe1-af5e-1c7d1db11fec">

10. Go the databand web ui (use http instead of https), and login with databand and databand. <br>
<img width="1551" alt="image" src="https://media.github.ibm.com/user/51730/files/0b942c95-67e5-4b1d-931d-b7382cc35756">












_________________
Notes:
* If you see this CERTIFICATE_VERIFY_FAILED error: `<urlopen error [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1129)>` run the following to solve the issue:
```
import os
import certifi
import urllib
os.environ["REQUESTS_CA_BUNDLE"] = certifi.where()
os.environ["SSL_CERT_FILE"] = certifi.where()
```
* In VS Code, to create a virtual environment:
1. Press cmd + p
2. Type `>python' then select create new environment
<img width="706" alt="image" src="https://media.github.ibm.com/user/51730/files/df96d2f9-0cbb-433f-bb94-f73967e60d31">
3. Choose either Venv or Conda (recommended).
4. Choose Python version:
 <img width="715" alt="image" src="https://media.github.ibm.com/user/51730/files/b1a13aef-c95f-4895-9aef-28cfdd4fa799">
 5. This will create a `.conda` folder in the working directory.
 6. When running a jupyter notebook for the first time in a virtual env, it will ask you to install `ipykernel`, just agree and proceed.
 7. To install pacakges, run this in a notebook `%pip install databand` instead of `!pip install databand`.
 8. For more details: https://code.visualstudio.com/docs/python/environments

