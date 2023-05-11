
###########################################
# user inputs: 4 items
###########################################

# run this script in ~/databank folder
# download the python script into this folder: https://github.ibm.com/Catherine-Cao/databand/blob/main/edit-user-values-yaml.py

# oc login
oc login --token=sha256~iajH3I6pdcVKx7TWEw_e6nPCoHsYGHDEY-MckAxJ2B0 --server=https://api.ocp-50avscmg0p-6er1.cloud.techzone.ibm.com:6443

#project name
project_name=databand

# the version might be different
tar_file_name=databand-v1.0.17.2-images.tar

# you can find it in the Tech Zone reservation details page
cluster_username=kubeadmin


###########################################

echo "Patching image repository..."

oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

echo "Getting image_route..."

oc get route -n openshift-image-registry

read -p 'Please provide image registry host url: ' image_registry_route

echo $image_registry_route

echo "creating a new project for databand..."

oc new-project $project_name --display-name $project_name

echo "loading images...."

docker load -i ../$tar_file_name

echo "preparing for image push..."

docker login $image_registry_route -u $cluster_username -p $(oc whoami -t)

version_tag=$(echo $tar_file_name | cut -d '-' -f 2)
image_repo=$(echo $image_registry_route/$project_name/)

image_names=(dbnd-ml-trainer:python-$version_tag \
             dbnd-datasource-monitor:python-$version_tag \
             dbnd-datastage-monitor:python-$version_tag \
             dbnd-dbt-monitor:python-$version_tag \
             dbnd-webserver:python-$version_tag \
             dbnd-alert-defs-syncer:python-$version_tag \
             dbnd-webapp:nginx-$version_tag)


echo "the following 7 will be pushed to the target repository"
counter=1
for t in ${image_names[@]}; do
    echo "pushing image $counter/7"
    docker tag registry.gitlab.com/databand/databand-deploy/$t $image_repo$t 
    docker push $image_repo$t
    echo "******************"
    counter=$[$counter+1]
    echo $t
done

echo "all images pushed..."

echo "generating keys"
fernet=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | openssl base64)
web_server_key=$(head -c 32 /dev/urandom | base64 | tr -d =)

cp user-values.yaml.example user-values.yaml

echo "configuring user-values.yaml..."
token=$(oc whoami -t)

pwd_=$(pwd)
pyscript_full_path=$(echo $pwd_/edit-user-values-yaml.py)

# make sure full path to the python script
python $pyscript_full_path "$image_repo" "$image_registry_route" "$cluster_username" "$token" "$fernet" "$web_server_key" || python3 $pyscript_full_path "$image_repo" "$image_registry_route" "$cluster_username" "$token" "$fernet" "$web_server_key"

echo "preparing for helm install..."

#if need to install helm: https://helm.sh/docs/intro/install/
#if using virtual env for python, try put .venv in .helmigore
helm upgrade databand --install --create-namespace --namespace $project_name  --values ./values-ocp.yaml --values ./user-values.yaml .

oc project $project_name

oc expose svc databand-web

echo "*************Databand url, make sure use http instead of https*************"

oc get routes

echo "*************databand login username: databand, pw: databand*************"

