#!/bin/bash

# DIY VPN Minikube Deployment Script
set -e

echo "🚀 DIY VPN Minikube Deployment"
echo "================================"

# Configuration
NAMESPACE="twingate"
RELEASE_NAME="diy-vpn-local"
VALUES_FILE="values.yaml"

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube is not installed. Please install it first."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Check if Minikube is running
echo "🔍 Checking Minikube status..."
if ! minikube status &> /dev/null; then
    echo "⚠️  Minikube is not running. Starting Minikube..."
    minikube start --cpus=2 --memory=4096 --driver=docker
else
    echo "✅ Minikube is running"
fi

# Verify cluster connectivity
echo "🔗 Verifying cluster connectivity..."
kubectl cluster-info > /dev/null
echo "✅ Cluster connectivity verified"

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo "⚠️  Values file '$VALUES_FILE' not found."
    if [ -f "values-example.yaml" ]; then
        echo "📝 Copying example values file..."
        cp values-example.yaml "$VALUES_FILE"
        echo "📝 Please edit '$VALUES_FILE' with your Twingate credentials before continuing."
        echo "   Required fields:"
        echo "   - network: your-tenant-name"
        echo "   - apiKey: your-twingate-api-key"
        echo ""
        read -p "Press Enter after editing the values file..."
    else
        echo "❌ No example values file found. Please create '$VALUES_FILE'"
        exit 1
    fi
fi

# Update Helm dependencies
echo "📦 Updating Helm dependencies..."
cd ../helm
helm dependency update
cd ../minikube

# Deploy with Helm
echo "🚀 Deploying DIY VPN to Minikube..."
helm upgrade --install "$RELEASE_NAME" ../helm \
    -f "$VALUES_FILE" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait \
    --timeout 5m

echo "✅ Deployment completed!"

# Show status
echo ""
echo "📊 Deployment Status:"
echo "===================="
kubectl get pods -n "$NAMESPACE"
echo ""

echo "🔍 TwingateConnector Status:"
echo "==========================="
kubectl get twingateconnectors -n "$NAMESPACE" 2>/dev/null || echo "No connectors found yet (this is normal during initial startup)"

echo ""
echo "🎉 DIY VPN deployed successfully to Minikube!"
echo ""
echo "📝 Useful commands:"
echo "  # Check operator logs:"
echo "  kubectl logs -l app.kubernetes.io/name=twingate-operator -n $NAMESPACE -f"
echo ""
echo "  # Check connector status:"
echo "  kubectl get twingateconnectors -n $NAMESPACE"
echo ""
echo "  # Port forward for debugging (if metrics available):"
echo "  kubectl port-forward -n $NAMESPACE service/$RELEASE_NAME-twingate-operator 8080:8080"
echo ""
echo "  # Uninstall:"
echo "  helm uninstall $RELEASE_NAME -n $NAMESPACE"