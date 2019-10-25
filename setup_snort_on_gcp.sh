#!/bin/sh

./setup_ids_project.sh $@ && \
gcloud compute ssh ids-bridge -- < ./snort/install_snort_3.0.sh
