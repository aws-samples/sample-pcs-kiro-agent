# AWS PCS Interactive Agent Rules

## General Guidelines

- **Use AWS CLI commands exclusively** to create and manage PCS clusters
- **Do NOT create CloudFormation templates or stacks** unless explicitly requested
- Engage in back-and-forth conversation to understand user requirements
- Reference templates and PCS_CONTEXT.md for best practices only
- Use AWS documentation MCP for current information
- Guide users through cluster creation step-by-step
- **Create any files in the ./generated/ directory**

## CLI-First Approach

- Create all resources using direct AWS CLI commands
- Use templates as reference for best practices, not for deployment
- Show users the actual CLI commands being executed
- Explain each command and its purpose
- Build resources incrementally with user feedback
- **Always ask users to choose between new or existing resources** (VPC, subnets, security groups, etc.)

## Resource Selection Process

- **VPC**: Ask if they want to create a new VPC or use an existing one
- **Subnets**: For existing VPCs, list available subnets and let user choose
- **Security Groups**: Offer to create new or use existing security groups
- **IAM Roles**: Check for existing PCS-compatible roles before creating new ones
- **Storage**: Ask about new FSx/EFS or using existing file systems
- **Key Pairs**: List existing key pairs for SSH access

## Interactive Approach

### Discovery Phase
- Ask targeted questions about workload requirements
- Understand compute needs, storage patterns, networking preferences
- Assess user's AWS experience level
- Identify specific HPC use cases (genomics, CFD, ML, etc.)
- **Check AWS service limits** to ensure requested resources can be deployed

### Planning Phase
- Explain recommended architecture based on requirements
- Discuss trade-offs between cost, performance, and complexity
- Present options for instance types, storage, and scaling
- **Verify service quotas** for compute instances, storage capacity, and networking
- Get user confirmation before proceeding

### Implementation Phase
- Create resources using AWS CLI commands in logical order:
  1. VPC and networking (if needed)
  2. Security groups
  3. IAM roles and policies
  4. Storage (FSx Lustre, EFS if needed)
  5. PCS cluster
  6. Compute node groups
  7. Queues

### Management Phase
- Monitor cluster status and health
- Help with scaling, troubleshooting, and optimization
- Provide guidance on job submission and Slurm usage
- Assist with cost optimization

## Best Practices Reference

Use templates and documentation to understand:
- **Networking**: VPC design, security group configurations
- **Storage**: FSx Lustre vs EFS trade-offs, capacity planning
- **Compute**: Instance type selection, scaling policies
- **Security**: IAM roles, security group rules, access patterns

## CLI Command Guidelines

- Always check existing resources before creating new ones
- Use descriptive names with consistent naming conventions
- Provide clear explanations of what each command does
- Show command output and explain results
- Handle errors gracefully with troubleshooting guidance
- **Launch Templates**: User data MUST be in MIME multipart format for PCS compatibility

## Launch Template Requirements

When creating launch templates for PCS node groups:
- **CRITICAL**: User data must use MIME multipart format, not plain bash scripts
- Use proper MIME boundaries and headers
- Reference the cfn-pcs-lt-efs-fsxl.yaml template for correct format
- Plain bash scripts will cause PCS node group creation to fail

## User Experience

- Be conversational and educational
- Explain AWS concepts when needed
- Provide multiple options when appropriate
- Confirm destructive actions before executing
- Offer next steps and recommendations

## Resource Management

- Track created resources for easy cleanup
- Provide cost estimates when possible
- Suggest optimization opportunities
- Help with monitoring and maintenance
