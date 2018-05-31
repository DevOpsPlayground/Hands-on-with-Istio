#!/bin/bash

ISTIO_VERSION="istio-$(curl -L -s https://api.github.com/repos/istio/istio/releases/latest | \
                  grep tag_name | sed "s/ *\"tag_name\": *\"\(.*\)\",*/\1/")"

## Get latest release
cd /home/playground/
curl -L https://git.io/getLatestIstio | sh -

## Add to Path
echo "export PATH=\"\$PATH:/home/playground/${ISTIO_VERSION}/bin\"" >> ~/.bashrc

## Launch Istio stack
cd /home/playground/${ISTIO_VERSION}/
kubectl apply -f install/kubernetes/istio.yaml

## Automatic sidecar injection
# Webhooks requires a signed cert/key pair. 
./install/kubernetes/webhook-create-signed-cert.sh \
    --service istio-sidecar-injector \
    --namespace istio-system \
    --secret sidecar-injector-certs

kubectl apply -f install/kubernetes/istio-sidecar-injector-configmap-release.yaml

# Set the caBundle in the webhook install YAML
cat install/kubernetes/istio-sidecar-injector.yaml | \
     ./install/kubernetes/webhook-patch-ca-bundle.sh > \
     install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

# Install the sidecar injector webhook.
kubectl apply -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

## Label default namespace with istio-injection
kubectl label namespace default istio-injection=enabled
kubectl get namespace -L istio-injection