#!/bin/bash

# AWS PCS Cluster Setup Completion Script
# This script monitors cluster status and completes the setup

CLUSTER_ID="pcs_pekig466jx"
REGION="us-east-1"

echo "🔍 Monitoring AWS PCS Cluster: $CLUSTER_ID"
echo "⏳ Waiting for cluster to become ACTIVE..."

# Function to check cluster status
check_cluster_status() {
    aws pcs get-cluster --cluster-identifier $CLUSTER_ID --region $REGION --query 'cluster.status' --output text
}

# Wait for cluster to be ACTIVE
while true; do
    STATUS=$(check_cluster_status)
    echo "Current status: $STATUS"
    
    if [ "$STATUS" = "ACTIVE" ]; then
        echo "✅ Cluster is now ACTIVE!"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo "❌ Cluster creation failed!"
        exit 1
    fi
    
    echo "⏳ Still creating... checking again in 30 seconds"
    sleep 30
done

echo ""
echo "🚀 Creating compute node group..."

# Create compute node group
aws pcs create-compute-node-group \
    --cluster-identifier $CLUSTER_ID \
    --compute-node-group-name "scientific-compute-nodes" \
    --custom-launch-template id=lt-0cb1bec39fe958237,version='$Latest' \
    --iam-instance-profile-arn "arn:aws:iam::498737083963:instance-profile/PCSComputeNodeInstanceProfile" \
    --instance-configs instanceType=c5.large instanceType=c5.xlarge \
    --scaling-configuration minInstanceCount=0,maxInstanceCount=8 \
    --subnet-ids "subnet-0c87cacf0e8afe9fe" \
    --tags Environment=Development,Purpose=Scientific-Computing \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Compute node group created successfully!"
else
    echo "❌ Failed to create compute node group"
    exit 1
fi

echo ""
echo "🎯 Creating queue for job submission..."

# Create queue
aws pcs create-queue \
    --cluster-identifier $CLUSTER_ID \
    --queue-name "scientific-queue" \
    --compute-node-group-configurations computeNodeGroupId=scientific-compute-nodes \
    --tags Environment=Development,Purpose=Scientific-Computing \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Queue created successfully!"
else
    echo "❌ Failed to create queue"
    exit 1
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Your AWS PCS cluster is ready for scientific computing!"
echo ""
echo "📋 Cluster Details:"
echo "   • Cluster ID: $CLUSTER_ID"
echo "   • Name: scientific-hpc-cluster"
echo "   • Scheduler: Slurm 24.05"
echo "   • Size: SMALL (32 nodes max, 256 jobs max)"
echo "   • Instance Types: c5.large, c5.xlarge"
echo "   • Auto-scaling: 0-8 nodes"
echo ""
echo "🔑 SSH Key: hpc-pcs-keypair.pem (in current directory)"
echo ""
echo "📝 Next Steps:"
echo "   1. Connect to cluster head node (when available)"
echo "   2. Submit test jobs with 'sbatch'"
echo "   3. Monitor with 'squeue' and 'sinfo'"
echo ""
echo "💡 Useful Commands:"
echo "   • Check cluster: aws pcs get-cluster --cluster-identifier $CLUSTER_ID --region $REGION"
echo "   • List nodes: aws pcs list-compute-node-groups --cluster-identifier $CLUSTER_ID --region $REGION"
echo "   • View queues: aws pcs list-queues --cluster-identifier $CLUSTER_ID --region $REGION"
