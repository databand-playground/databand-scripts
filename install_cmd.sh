# the working directory should be where databand-1.0.15-docker-compose.tar.gz and ssh key file are.
cd <working-directory>

## change key file permission:
sudo chmod 600 pem_ibmcloudvsi_download.cer

# connect to VM: using 169.61.6.87 as an example
ssh itzuser@169.61.6.87 -p 2223 -i pem_ibmcloudvsi_download.cer 

# Install and test docker
sudo curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo docker run hello-world


# Install and test docker-compose
# Instructions from official docker documentation do not work: the first two commands run, but they state that docker compose is already installed. Then the last command does not find docker compose
# sudo apt-get update
# sudo apt-get install docker-compose-plugin
# docker compose version

# These instructions work. Note the hardcoded version of docker compose on curl command, which is not ideal and should be verified
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version


# Test installation of rsync
sudo rsync --version

# Copy installation files - via ssh or Filezilla to any directory
# exmaple for Mac: scp -P 2223 -i pem_ibmcloudvsi_download.cer databand-1.0.15-docker-compose.tar.gz itzuser@169.61.6.87:~/

# Change permissions on the copied file
sudo chmod 777 databand-1.0.15-docker-compose.tar.gz

# Untar the file in the installation directory
sudo tar -xvf databand-1.0.15-docker-compose.tar.gz

# Switch to the installation directory
cd databand-v1.0.15.5-docker-compose/installation
sudo ./databand-cmd.sh setup 
sudo ./databand-cmd.sh load-images
sudo ./databand-cmd.sh create-secrets

# Switch to the /opt/databand directory
cd /opt/databand
sudo vi custom.env
# Update custom.env to either use the local or external Postgres
# to use the local Postgres: press x to remove "# Example: " and comment out #COMPOSE_FILE=docker-compose.yml, see lab instructions for screenshots
# Vi commands helper:
	# i to insert, Esc to exit the insert mode
	# :wq to save the file

# From the /opt/databand run ./databand-cmd.sh start to start databand.
sudo ./databand-cmd.sh start

# Optional you can run ./databand-cmd.sh status to validate that everything is up and running.
sudo ./databand-cmd.sh status

# Create new Databand user by running command ./databand-cmd.sh create-user, follow interective prompt:
sudo ./databand-cmd.sh create-user

# Now you can access UI in the http://$INSTANCE_IP:8080/ URL, and login with user created in step 8.
http://169.61.6.87:8080/