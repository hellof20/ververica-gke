#!/bin/bash

echo "create bucket"
gcloud storage buckets create gs://$bucket --project=$project_id

echo "create iam service account"
gcloud iam service-accounts create gcs-vvp-service-acc \
--description="Service account for VVP GCS" \
--display-name="gcs-vvp-service-acc" \
--project=$project_id \
--quiet

echo "get service account json"
keyid=$(gcloud iam service-accounts keys list --iam-account=gcs-vvp-service-acc@speedy-victory-336109.iam.gserviceaccount.com --format="csv[no-heading](name)")
gcloud beta iam service-accounts keys get-public-key $keyid \
    --iam-account=gcs-vvp-service-acc@$project_id.iam.gserviceaccount.com \
    --output-file=gcs-key.json \
    --project=$project_id \
    --quiet

echo "asign permission to iam sa"
gcloud projects add-iam-policy-binding $project_id \
--member=serviceAccount:gcs-vvp-service-acc@$project_id.iam.gserviceaccount.com \
--role=roles/storage.admin \
--quiet

echo "create gke"
gcloud container clusters create $name \
    --cluster-version=1.23 \
    --no-enable-autoupgrade \
    --machine-type=e2-standard-4 \
    --num-nodes=1 \
    --zone $zone \
    --project=$project_id \
    --quiet

echo "create vvp namespace"
kubectl create namespace vvp

echo "create vvp secert"
kubectl create secret generic gcs-key --from-file=./gcs-key.json -n vvp

echo "deploy vvp with helm"
envsubst < values-template.yaml > values.yaml
helm repo add ververica https://charts.ververica.com
helm --namespace vvp install vvp ververica/ververica-platform --set acceptCommunityEditionLicense=true --values values.yaml


echo "expose as load balance"
kubectl --namespace vvp apply -f vvp-svc.yaml
waitTime=0
until [ $(kubectl -n vvp get svc vvp-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}') ]; do
    sleep 10;
    waitTime=$(expr ${waitTime} + 10)
    echo "waited ${waitTime} secconds for vvp svc to be ready ..."
    if [ ${waitTime} -gt 300 ]; then
        echo "wait too long, failed."
        return 1
    fi
done
vvp_external_ip=$(kubectl -n ${namespace} get svc mysql -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "vvp external ip is ${vvp_external_ip}"

