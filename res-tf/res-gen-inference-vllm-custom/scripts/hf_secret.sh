#!/usr/bin/env bash

kubectl create secret generic hf-token --from-literal=token=${HF_TOKEN} -n ${NS} || true
