# AWS PCS Technical Context and Best Practices

This document provides comprehensive technical knowledge for AWS Parallel Computing Service (PCS) cluster creation and management.

## Architecture Overview

### Core Components

**AWS PCS Cluster**
- Persistent resource for managing HPC workloads
- Built around Slurm job scheduler
- Controller runs in AWS-managed service account
- Communicates with compute resources in customer account

**Cluster Controller**
- Manages job scheduling and resource allocation
- Sizes: SMALL (100 nodes, 1000 jobs), MEDIUM (1000 nodes, 10000 jobs), LARGE (5000 nodes, 50000 jobs)
- Cannot be changed after cluster creation
- Automatically handles failover and scaling

**Compute Node Groups**
- Collections of EC2 instances for job execution
- Auto-scaling based on job queue demand
- Support multiple instance types within same group
- Can be dynamically added/removed from cluster

**Queues**
- Slurm partitions for organizing workloads
- Define access policies and resource limits
- Can target specific compute node groups
- Support priority-based scheduling

## Networking Requirements

### VPC Prerequisites

**Subnet Requirements**
- Minimum 1 available IP address per subnet
- Private subnets recommended for security
- Public subnets only if direct internet access needed
- IPv4 or IPv6 (not both simultaneously)

**VPC Configuration**
- DNS resolution and DNS hostnames must be enabled
- Route tables configured for internet access (via NAT or IGW)
- Sufficient IP address space for planned cluster size
- Consider multiple AZs for high availability

### Security Groups

**Minimum Required Rules**

*Controller Security Group*
```
Inbound:
- Port 6817-6818 (TCP) from compute node security groups - Slurm communication
- Port 22 (TCP) from admin security groups - SSH access (optional)

Outbound:
- All traffic to 0.0.0.0/0 - Internet access for package installation
```

*Compute Node Security Group*
```
Inbound:
- Port 6818 (TCP) from controller security group - Slurm daemon
- Port 22 (TCP) from login node security groups - SSH access
- All traffic from same security group - Inter-node communication

Outbound:
- All traffic to 0.0.0.0/0 - Internet access for packages and data
```

*Login Node Security Group*
```
Inbound:
- Port 22 (TCP) from user access ranges - SSH login
- Port 6817 (TCP) from controller security group - Slurm client

Outbound:
- All traffic to 0.0.0.0/0 - General internet access
```

## Storage Architecture

### Shared Storage Options

**Amazon EFS (Recommended for General Use)**
- POSIX-compliant NFS file system
- Automatic scaling and high availability
- Performance modes: General Purpose, Max I/O
- Throughput modes: Provisioned, Bursting
- Encryption at rest and in transit
- Cross-AZ replication available

**Amazon FSx for Lustre (High Performance)**
- High-performance parallel file system
- Optimized for compute-intensive workloads
- S3 integration for data lifecycle management
- Scratch and persistent file system types
- Sub-millisecond latencies, high throughput

**Amazon EBS (Node-Local Storage)**
- Block storage for individual compute nodes
- Multiple volume types: gp3, io2, st1, sc1
- Encryption and snapshot capabilities
- Not shared between nodes

### Storage Best Practices

**Mount Point Standards**
- `/home` - User home directories (EFS)
- `/shared` - Shared application data (EFS/FSx)
- `/scratch` - Temporary job data (local NVMe/EBS)
- `/apps` - Software installations (EFS)

**Performance Considerations**
- Use EFS for shared, moderate-performance needs
- Use FSx for high-performance, parallel workloads
- Use local NVMe for temporary, high-IOPS requirements
- Consider data locality for large datasets

## Compute Node Groups

### Instance Type Selection

**CPU-Optimized Families**
- `c5/c5n/c6i/c7i` - Balanced compute performance
- `m5/m6i/m7i` - General purpose with memory balance
- `r5/r6i/r7i` - Memory-optimized for large datasets
- `x1e/x2iezn` - High memory for in-memory computing

**GPU-Enabled Families**
- `p3/p4/p5` - ML training and HPC simulations
- `g4/g5` - Graphics workstations and visualization
- Consider GPU memory requirements vs cost

**Storage-Optimized**
- `i3/i4i` - NVMe SSD for high random I/O
- `d2/d3` - Dense HDD storage for analytics

### Scaling Configuration

**Auto Scaling Parameters**
- Scale-down idle time: 2-10 minutes typical
- Min capacity: 0 for cost optimization
- Max capacity: Based on budget and workload peaks
- Desired capacity: Typically 0 (demand-driven)

**Launch Template Requirements**
- Must specify AMI compatible with PCS
- Instance profile with required IAM permissions
- User data script for cluster joining
- Security group assignments
- Storage configuration

## Queue Management

### Queue Configuration Patterns

**Interactive Queue**
```yaml
- name: interactive
  computeNodeGroupConfigurations:
    - computeNodeGroupId: login-nodes
  priority: 100
  description: "Interactive development and debugging"
```

**Batch Queue**
```yaml
- name: batch
  computeNodeGroupConfigurations:
    - computeNodeGroupId: compute-nodes
  priority: 50
  description: "Production batch workloads"
```

**GPU Queue**
```yaml
- name: gpu
  computeNodeGroupConfigurations:
    - computeNodeGroupId: gpu-nodes
  priority: 75
  description: "GPU-accelerated computing"
```

### Resource Limits

**Per-User Limits**
- MaxJobs: Maximum concurrent jobs per user
- MaxSubmitJobs: Maximum jobs in queue per user
- MaxWall: Maximum job runtime
- MaxCPUs: Maximum CPU cores per user

**Per-Job Limits**
- DefCpuPerTask: Default CPUs per task
- MaxCpuPerNode: Maximum CPUs per node
- MaxMemPerCpu: Maximum memory per CPU
- MaxTime: Maximum job runtime

## Cluster Sizing Guidelines

### Development/Testing
- **Size**: SMALL
- **Nodes**: 1-10 compute nodes
- **Instance Types**: t3.medium, c5.large
- **Storage**: 100GB EFS General Purpose
- **Use Case**: Code development, small simulations

### Production/Research
- **Size**: MEDIUM
- **Nodes**: 10-100 compute nodes
- **Instance Types**: c5.xlarge, r5.xlarge
- **Storage**: 1TB+ EFS, FSx for high-performance
- **Use Case**: Production workloads, research simulations

### Large Scale/Commercial
- **Size**: LARGE
- **Nodes**: 100+ compute nodes
- **Instance Types**: c5n.18xlarge, p4d.24xlarge
- **Storage**: Multi-TB FSx, tiered storage
- **Use Case**: Commercial HPC, AI/ML training

## Cost Optimization

### Instance Strategy
- Use Spot instances for fault-tolerant workloads
- Mix On-Demand and Spot for availability
- Right-size instances based on workload profiling
- Consider Reserved Instances for steady-state capacity

### Storage Optimization
- EFS Infrequent Access for archive data
- FSx periodic file system for temporary data
- S3 integration for long-term data storage
- Lifecycle policies for automated tiering

### Operational Efficiency
- Implement cluster hibernation for development
- Use CloudWatch metrics for utilization monitoring
- Set up billing alerts and cost tracking
- Regular cleanup of unused resources

## IAM Roles and Permissions

### PCS Service Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pcs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Compute Node Instance Profile
**Required Policies**:
- `AmazonSSMManagedInstanceCore` - Systems Manager
- `CloudWatchAgentServerPolicy` - Monitoring
- Custom policy for EFS/FSx access

### User Access Policies
- `PCSFullAccess` - Complete cluster management
- `PCSReadOnlyAccess` - View cluster status
- Custom policies for specific operations

## Slurm Configuration

### Key Parameters

**SelectTypeParameters**
- `CR_CPU` - CPU-only scheduling
- `CR_CPU_Memory` - Memory-aware scheduling (recommended)

**Accounting Configuration**
- Enable for job tracking and billing
- Requires external database (RDS recommended)
- Configure with cluster creation

**Prolog/Epilog Scripts**
- Must be directories, not files
- Run before/after each job
- Useful for environment setup and cleanup

### Job Submission Examples

**Basic CPU Job**
```bash
#!/bin/bash
#SBATCH --job-name=my-job
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --time=01:00:00
#SBATCH --partition=batch

srun my-application
```

**GPU Job**
```bash
#!/bin/bash
#SBATCH --job-name=gpu-job
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --time=02:00:00
#SBATCH --partition=gpu

nvidia-smi
srun ./gpu-application
```

## Monitoring and Troubleshooting

### CloudWatch Metrics
- Cluster health and job queue status
- Compute node utilization and scaling events
- Storage performance and capacity metrics
- Cost and billing information

### Common Issues

**Compute Nodes Not Starting**
- Check security group rules
- Verify IAM permissions
- Review launch template configuration
- Check subnet capacity and limits

**Jobs Stuck in Queue**
- Verify resource requests vs availability
- Check queue configuration and limits
- Review node state and availability
- Examine Slurm logs for errors

**Storage Access Issues**
- Verify EFS/FSx mount targets
- Check security group rules for NFS
- Review IAM permissions for storage access
- Test network connectivity to storage

### Log Locations
- Slurm logs: `/var/log/slurm/`
- System logs: `/var/log/messages`
- CloudWatch Logs for centralized logging
- AWS PCS service logs via API

## Integration Patterns

### CI/CD Integration
- Infrastructure as Code with CloudFormation
- Automated testing with parallel job execution
- Container-based workloads with Docker/Singularity
- Integration with CodePipeline and CodeBuild

### Data Pipeline Integration
- S3 data lakes for input/output
- AWS Batch for containerized workloads
- Step Functions for workflow orchestration
- EventBridge for job completion notifications

### ML/AI Workflows
- SageMaker integration for model training
- Jupyter notebooks for interactive development
- Model serving with ECS/EKS
- MLOps pipelines with automated retraining

## CLI Command Reference

### Cluster Management
```bash
# Create cluster
aws pcs create-cluster --cluster-name my-cluster \
  --scheduler type=SLURM,version=24.11 \
  --size SMALL \
  --networking subnetIds=subnet-12345,securityGroupIds=sg-12345

# List clusters
aws pcs list-clusters

# Describe cluster
aws pcs get-cluster --cluster-name my-cluster

# Delete cluster
aws pcs delete-cluster --cluster-name my-cluster
```

### Compute Node Groups
```bash
# Create compute node group
aws pcs create-compute-node-group \
  --cluster-name my-cluster \
  --compute-node-group-name batch-nodes \
  --scaling-policy type=BEST_FIT_PROGRESSIVE,minInstanceCount=0,maxInstanceCount=10

# List compute node groups
aws pcs list-compute-node-groups --cluster-name my-cluster

# Update scaling
aws pcs update-compute-node-group \
  --cluster-name my-cluster \
  --compute-node-group-name batch-nodes \
  --scaling-policy maxInstanceCount=20
```

### Queue Management
```bash
# Create queue
aws pcs create-queue \
  --cluster-name my-cluster \
  --queue-name batch \
  --compute-node-group-configurations computeNodeGroupId=batch-nodes

# List queues
aws pcs list-queues --cluster-name my-cluster

# Update queue
aws pcs update-queue \
  --cluster-name my-cluster \
  --queue-name batch \
  --compute-node-group-configurations computeNodeGroupId=batch-nodes,priority=100
```

This technical context provides the foundation for creating robust, scalable, and cost-effective AWS PCS clusters following AWS best practices.