# Deploy Ververica Platform on GKE

[Ververica Platform](https://www.ververica.com/) is an integrated platform for stateful stream processing and streaming analytics with Open Source Apache Flink. It enables organizations of any size to derive immediate insight from their data and serve internal and external stakeholders.

This demo is helps to deploy Ververica Platform [Community Edition](https://www.ververica.com/pricing-editions) on Google Cloud GKE step by step.

## Deploy

### Prerequisite
- You must have Google Cloud permissions to create GKE cluster, GCS bucket and IAM service account.
- Command line tools
    - gcloud
    - helm
    - git
    - kubectl
- Change org policy(only for Aroglis users)
    - constraints/iam.disableServiceAccountKeyCreation to Not enforced
    - constraints/compute.requireShieldedVm to Not enforced
    - constraints/compute.vmExternalIpAccess to allow all

### Set environment variable
```
export project_id=your_project_id
export bucket=bucket-name-for-ververica
export zone=us-central1-a
```

### Create a GCS bucket, in order to enable universal blob storage
```
gcloud storage buckets create gs://$bucket --project=$project_id
```

### Create iam service account and assign permission to it
```
gcloud iam service-accounts create gcs-vvp-service-acc \
--description="Service account for VVP GCS" \
--display-name="gcs-vvp-service-acc" \
--project=$project_id 
```
```
gcloud iam service-accounts keys create gcs-key.json \
    --iam-account=gcs-vvp-service-acc@$project_id.iam.gserviceaccount.com \
    --key-file-type json
```
```
gcloud projects add-iam-policy-binding $project_id \
--member=serviceAccount:gcs-vvp-service-acc@$project_id.iam.gserviceaccount.com \
--role=roles/storage.admin
```

### Create a GKE cluster
```
gcloud compute networks create ververica-demo-network --subnet-mode=auto
gcloud services enable container
gcloud container clusters create ververica-demo \
    --cluster-version=1.23 \
    --no-enable-autoupgrade \
    --machine-type=e2-standard-4 \
    --num-nodes=1 \
    --network ververica-demo-network \
    --zone $zone \
    --project=$project_id
 ```
 
### Get the GKE cluster credential after cluster create finished
```
gcloud container clusters get-credentials ververica-demo \
    --zone $zone \
    --project=$project_id
```

### Create a namespace named vvp
```
kubectl create namespace vvp
```

### Create a secert from service account json file in vvp namespace
```
kubectl create secret generic gcs-key --from-file=./gcs-key.json -n vvp
```

### Deploy Ververica Platform Community Edition with Helm
```
git clone https://github.com/hellof20/ververica-gke.git
cd ververica-gke
envsubst < values-template.yaml > values.yaml
helm repo add ververica https://charts.ververica.com
helm --namespace vvp install vvp ververica/ververica-platform --set acceptCommunityEditionLicense=true --values values.yaml
```

### Expose vvp with load balance
```
kubectl --namespace vvp apply -f vvp-svc.yaml
```
### Wait a minute until vvp deployment and svc is running
![image](https://user-images.githubusercontent.com/8756642/219956918-b80425ef-b347-48c9-80d5-d4bdbacedd22.png)

### Get the load balance ip address and access it from web browser
```
vvp_external_ip=$(kubectl -n vvp get svc vvp-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Access your VVP: http://${vvp_external_ip}"
```
![image](https://user-images.githubusercontent.com/8756642/215326077-128eff1e-a078-45a4-a8d9-957204adcf31.png)

## Useage

### [Getting Started - Flink SQL](https://docs.ververica.com/getting_started/sql_development.html)

### [Getting Started - Flink Operations](https://docs.ververica.com/getting_started/flink_operations.html)
