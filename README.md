# EKS Cluster Provisioning with Private Nodes via NAT Gateways

This project provides Terraform configuration to provision a secure and scalable Amazon Elastic Kubernetes Service (EKS) cluster. To enhance security, worker nodes and the control plane within private subnets, using NAT Gateways for outbound internet access.

**Key Features:**

- **VPC Configuration:** Creates a Virtual Private Cloud (VPC) with three private and three public subnets across multiple Availability Zones for high availability.
- **Private Subnet Deployment:** Deploys both the EKS control plane and worker nodes in private subnets, increasing security by limiting direct internet exposure.
- **NAT Gateway for Outbound Access:** Configures NAT Gateways in the public subnets to allow worker nodes in the private subnets to initiate outbound internet connections (e.g., for pulling container images) without being publicly accessible.
- **Internet Gateway:** Provides internet access for the public subnets, necessary for the NAT Gateways.
- **Route Table Configuration:** Sets up appropriate route tables to direct traffic within the VPC and to the internet via the NAT Gateways.
- **EKS Cluster Creation:** Provisions an EKS cluster within the specified private subnets.
- **Managed Node Group:** Creates a managed node group with worker nodes deployed in the private subnets.
- **IAM Roles:** Includes the necessary IAM roles for the EKS cluster and node group.
- **Security Groups:** Configures security groups to control inbound and outbound traffic for the EKS control plane and worker nodes.
- **Kubernetes Provider Configuration:** Sets up the Terraform Kubernetes provider to interact with the provisioned EKS cluster.
- **Admin User Access:** Optionally configures a `ClusterRoleBinding` to grant the user running Terraform `cluster-admin` privileges.
- **Helm Provider (Example):** Includes an example of how to configure the Helm provider for deploying applications like the Nginx Ingress Controller.

**Intended Use:**

This project serves as a foundation for deploying a production-ready EKS cluster with a focus on network security. Consider customizing and extending this configuration to meet specific application requirements.
In particular:

- consider adding your own backend for terraform state storage & management.
- change the name and specify the region where you want to deploy
- add your variables (e.g. in a `terraform.tfvars` or a specific file for prod/dev)

**After Provisioning:**

After provisioning the cluster using this configuration, the next steps typically involve:

- Configuring `kubectl` to interact with the cluster:
  - `aws eks update-kubeconfig --name development-eks-cluster --region <your_aws_region>`
- Verify connectivity:
  - `kubectl get namespaces`
  - `kubectl get nodes`
  - `kubectl get pods -n kube-system`
- Implementing further security measures like Network Policies and Secrets Management.
