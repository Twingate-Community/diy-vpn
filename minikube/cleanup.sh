#!/bin/bash

# DIY VPN Minikube Cleanup Script
set -e

echo "🧹 DIY VPN Minikube Cleanup"
echo "==========================="

# Configuration
NAMESPACE="twingate"
RELEASE_NAME="diy-vpn-local"

echo "⚠️  This will remove the DIY VPN deployment from Minikube."
echo "   Release: $RELEASE_NAME"
echo "   Namespace: $NAMESPACE"
echo ""

# Confirm deletion
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo "🗑️  Removing Helm release..."
if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
    helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
    echo "✅ Helm release removed"
else
    echo "ℹ️  No Helm release found"
fi

echo "🗑️  Cleaning up Twingate resources..."
# Force delete any TwingateConnector resources first
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "   Removing TwingateConnector resources..."
    kubectl delete twingateconnectors --all -n "$NAMESPACE" --ignore-not-found=true --timeout=30s || true
    
    echo "   Removing any remaining pods..."
    kubectl delete pods --all -n "$NAMESPACE" --ignore-not-found=true --timeout=30s || true
    
    echo "   Patching finalizers if stuck..."
    # Remove finalizers from any stuck resources
    kubectl get twingateconnectors -n "$NAMESPACE" -o name 2>/dev/null | while read resource; do
        kubectl patch "$resource" -n "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
    done
fi

echo "🗑️  Cleaning up cluster-wide resources..."
# Clean up any cluster-wide resources that might be left
kubectl delete clusterrole,clusterrolebinding -l app.kubernetes.io/name=twingate-operator --ignore-not-found=true

echo "🗑️  Removing namespace..."
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    # Try graceful deletion first
    kubectl delete namespace "$NAMESPACE" --timeout=30s &
    NAMESPACE_PID=$!
    
    # Wait for graceful deletion or force it
    sleep 5
    if kill -0 $NAMESPACE_PID 2>/dev/null; then
        echo "   Namespace deletion taking too long, forcing cleanup..."
        kill $NAMESPACE_PID 2>/dev/null || true
        
        # Force delete by removing finalizers
        kubectl patch namespace "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        sleep 2
    fi
    
    # Verify namespace is gone
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo "⚠️  Namespace still exists, but continuing..."
    else
        echo "✅ Namespace removed"
    fi
else
    echo "ℹ️  Namespace not found"
fi

echo "✅ Cleanup completed!"

# Optional: Ask if user wants to stop Minikube
echo ""
read -p "Do you want to stop Minikube as well? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⏹️  Stopping Minikube..."
    minikube stop
    echo "✅ Minikube stopped"
else
    echo "ℹ️  Minikube left running"
fi

echo ""
echo "🎉 Cleanup completed!"
echo ""
echo "📝 To restart:"
echo "  ./deploy.sh"
echo ""
echo "📝 To delete Minikube entirely:"
echo "  minikube delete"