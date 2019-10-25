#!/bin/bash


# Parsing User Input and Usage Validation
USAGE_TEXT="Usage: $0 [-hd] -p \$PROJECT_ID_ID -z \$ZONE"
CLEAR_PROJECT=false

while getopts ":hdp:z:" opt; do
  case $opt in
    h)
      echo $USAGE_TEXT 1>&2
      echo "-h (optional) help"
      echo "-d (optional) deletes the architecture deployed by this script and any and all dependencies (networks, subnets, routes, firewall rules, instances)"
      echo "-p \$PROJECT_ID (required) specify the project ID in which this script should operate"
      echo "-z \$ZONE (required) specify the zone in which this script should operate"
      ;;
    d) CLEAR_PROJECT=true;;
    p) PROJECT_ID="$OPTARG";;
    z) ZONE="$OPTARG"; REGION=${OPTARG:0:${#OPTARG} -2};;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo $USAGE_TEXT 1>&2
      exit 1
      ;;
    :)
      echo "Invalid Option: -$OPTARG requires an argument"
      echo $USAGE_TEXT 1>&2
      echo "$0 -h for more details" 1>&2
      exit 1
      ;;
  esac
done

if [[ ${#PROJECT_ID} -eq 0 ]]; then
  echo "$\PROJECT_ID Must be specified" 1>&2
  echo $USAGE_TEXT 1>&2
  exit 1
fi

if [[ ${#ZONE} -eq 0 ]]; then
  echo "\$ZONE Must be specified" 1>&2
  echo $USAGE_TEXT 1>&2
  exit 1
fi

# Clear project contents if the -r flag has been provided
EXTERNAL_NET="external"
INTERNAL_NET="internal"
if [[ $CLEAR_PROJECT ]]; then
  GAPI_NETWORK_URL="https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/networks/"

  # Delete all instances using the networking architecture that was deployed by this script
  echo 'Deleting VMs'
  gcloud compute instances list --filter="networkInterfaces.network='$GAPI_NETWORK_URL$EXTERNAL_NET'" | tail -n+2 | awk '{print $1 " --zone " $2}' | xargs -n 3 gcloud -q --verbosity=warning compute instances delete
  gcloud compute instances list --filter="networkInterfaces.network='$GAPI_NETWORK_URL$INTERNAL_NET'" | tail -n+2 | awk '{print $1 " --zone " $2}' | xargs -n 3 gcloud -q --verbosity=warning compute instances delete

  # Clear the networking architecture that was deployed by this script
  echo 'Deleteing firewall rules'
  gcloud compute firewall-rules list --filter="network='$EXTERNAL_NET'" | tail -n+2 | awk '{print $1}' ORS=' ' | xargs gcloud -q compute firewall-rules delete
  gcloud compute firewall-rules list --filter="network='$INTERNAL_NET'" | tail -n+2 | awk '{print $1}' ORS=' ' | xargs gcloud -q compute firewall-rules delete
  echo 'Deleting subnets'
  gcloud compute networks subnets list --filter="network='$GAPI_NETWORK_URL$EXTERNAL_NET'" | tail -n+2 | awk '{print $1 " --region " $2}' | xargs -n 3 gcloud -q compute networks subnets delete
  gcloud compute networks subnets list --filter="network='$GAPI_NETWORK_URL$INTERNAL_NET'" | tail -n+2 | awk '{print $1 " --region " $2}' | xargs -n 3 gcloud -q compute networks subnets delete
  echo 'Deleting routes'
  gcloud compute routes list --filter="network='$EXTERNAL_NET'" | tail -n+2 | awk '{print $1}' ORS=' ' | xargs gcloud -q compute routes delete
  gcloud compute routes list --filter="network='$INTERNAL_NET'" | tail -n+2 | awk '{print $1}' ORS=' ' | xargs gcloud -q compute routes delete
  echo 'Deleting networks'
  gcloud compute networks list --filter="name=(external,internal)" | tail -n+2 | awk '{print $1}' ORS=' ' | xargs gcloud -q compute networks  delete
fi

# Create an external network and an internal network
echo 'Creating an external network and an internal network'
gcloud compute networks create $EXTERNAL_NET \
    --project $PROJECT_ID \
    --subnet-mode custom && \
gcloud compute networks create $INTERNAL_NET \
    --project $PROJECT_ID \
    --subnet-mode custom

# Create subnets
echo 'Creating subnets'
EXTERNAL_SUBNET=$EXTERNAL_NET"1"
INTERNAL_SUBNET=$INTERNAL_NET"1"
EXTERNAL_SUBNET_RANGE=10.128.0.0/20
INTERNAL_SUBNET_RANGE=10.132.0.0/20

gcloud compute networks subnets create $EXTERNAL_SUBNET  \
    --project $PROJECT_ID \
    --network $EXTERNAL_NET \
    --region $REGION \
    --range $EXTERNAL_SUBNET_RANGE && \
gcloud compute networks subnets create $INTERNAL_SUBNET \
    --project $PROJECT_ID \
    --network $INTERNAL_NET \
    --region $REGION \
    --range $INTERNAL_SUBNET_RANGE

# Create firewall rules for the new networks
echo 'Creating firewall rules for the new networks'
gcloud compute firewall-rules create external-allow-all \
    --project $PROJECT_ID \
    --allow tcp,udp,icmp \
    --network $EXTERNAL_NET && \
gcloud compute firewall-rules create internal-allow-internal \
    --project $PROJECT_ID \
    --allow tcp,udp,icmp \
    --network $INTERNAL_NET \
    --source-ranges 10.0.0.0/8

# Create a service VM and an IDS VM in the external network
echo 'Creating a service VM and an IDS VM in the external network'
IDS_BRIDGE_INSTANCE=ids-bridge
gcloud compute instances create service-vm \
    --project $PROJECT_ID \
    --zone $ZONE \
    --network $EXTERNAL_NET \
    --subnet $EXTERNAL_SUBNET \
    --scopes compute-rw && \
gcloud compute instances create $IDS_BRIDGE_INSTANCE \
    --project $PROJECT_ID \
    --zone $ZONE \
    --network-interface subnet=$EXTERNAL_SUBNET \
    --network-interface subnet=$INTERNAL_SUBNET,no-address \
    --can-ip-forward

# Create a VM in the protected, internal network
echo 'Creating a VM in the protected, internal network'
gcloud compute instances create backend-service \
    --project $PROJECT_ID \
    --zone $ZONE \
    --network $INTERNAL_NET \
    --subnet $INTERNAL_SUBNET \
    --no-address

# Create routes to pass traffic from the external network to the internal
gcloud beta compute routes create external-to-internal \
--project $PROJECT_ID \
--network $EXTERNAL_NET \
--destination-range $INTERNAL_SUBNET_RANGE \
--next-hop-instance $IDS_BRIDGE_INSTANCE \
--next-hop-instance-zone $ZONE && \

gcloud beta compute routes create internal-to-external \
--project $PROJECT_ID \
--network $INTERNAL_NET \
--destination-range 0.0.0.0/0 \
--next-hop-instance $IDS_BRIDGE_INSTANCE \
--next-hop-instance-zone $ZONE && \


echo 'Done.'
