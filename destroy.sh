#!/bin/bash

echo "begin to destroy..."

echo "delete gcs-key.json"
rm -rf ./gcs-key.json

echo "delete iam sa"
gcloud iam service-accounts delete gcs-vvp-service-acc@speedy-victory-336109.iam.gserviceaccount.com --quiet

echo "delete bucket"
gcloud storage buckets delete gs://$bucket --project=$project_id --quiet

echo "delete gke cluster"
gcloud container clusters delete $name \
    --zone $zone \
    --project=$project_id \
    --quiet
