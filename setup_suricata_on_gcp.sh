#!/bin/sh

./setup_ids_project.sh $@ && \
gcloud compute ssh ids-bridge -- < ./suricata/install_suricata_3.2.1.sh
