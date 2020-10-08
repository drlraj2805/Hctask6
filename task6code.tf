## Declaring  Provider
provider "aws" {
  region = "ap-south-1"
 // your profile for AWS here.
 profile = "task2"   
}


//Security Group for RDS
	resource "aws_security_group" "sg_rds" {
		name        = "sg_rds"
		description = "Sec Group for RDS"
	

		ingress {
			from_port   = 3306
			to_port     = 3306
			protocol    = "tcp"
			cidr_blocks = ["0.0.0.0/0"]
		}
	}
	

	

	

	//Launching the RDS MySQL Database
	resource "aws_db_instance" "wp_rds" {
		engine            = "mysql"
		engine_version    = "5.7.21"
		identifier        = "mysql-db"
		username          = "divya"
		password          = "divya1234"
		instance_class    = "db.t2.micro"
		storage_type      = "gp2"
		allocated_storage = 15
		publicly_accessible = true
		vpc_security_group_ids = [aws_security_group.sg_rds.id ]
		port = 3306
	

		name = "wprdsdb"
		skip_final_snapshot = true
		final_snapshot_identifier = "fnlSnpt"
	

		auto_minor_version_upgrade = false
	  
		depends_on = [aws_security_group.sg_rds]
	}
	

	

	

	

	//Connecting to Kubernetes in Local System with minikube
	provider "kubernetes" {
	}
	

	

	

	//Launching PVC for WordPress
	resource "kubernetes_persistent_volume_claim" "pvc_wp" {
		depends_on = [aws_db_instance.wp_rds]
		metadata {
			name   = "pvc-wp"
			labels = {
			env     = "Production"
			Country = "India" 
			}
		}
	

		wait_until_bound = false
		spec {
			access_modes = ["ReadWriteOnce"]
			resources {
				requests = {
				storage = "5Gi"
				}
			}
		}
	}
	

	

	

	//Launching WordPress Deployment
	resource "kubernetes_deployment" "wp" {
		metadata {
			name   = "wp"
			labels = {
			env     = "Prod"
			Country = "Ind" 
			}
		}
		depends_on = [kubernetes_persistent_volume_claim.pvc_wp]
		spec {
			replicas = 1
			selector {
				match_labels = {
					pod     = "wp"
					env     = "Prod"
					Country = "Ind" 
	        
				}
			}
	

			template {
				metadata {
					labels = {
						pod     = "wp"
						env     = "Prod"
						Country = "Ind"  
					}
				}
	

				spec {
					volume {
						name = "wp-vol"
						persistent_volume_claim { 
							claim_name = kubernetes_persistent_volume_claim.pvc_wp.metadata.0.name
						}
					}
	

					container {
						image = "wordpress"
						name  = "wp-app"
	

						env {
							name  = "WORDPRESS_DB_HOST"
							value = aws_db_instance.wp_rds.address
						}
						env {
							name  = "WORDPRESS_DB_USER"
							value = "divya"
						}
						env {
							name  = "WORDPRESS_DB_PASSWORD"
							value = "divya1234"
						}
						env{
							name  = "WORDPRESS_DB_NAME"
							value = "wprdsdb"
						}
						env{
							name  = "WORDPRESS_TABLE_PREFIX"
							value = "wp_"
						}
	

						volume_mount {
							name       = "wp-vol"
							mount_path = "/var/www/html/"
						}
	

						port {
							container_port = 80
						}
					}
				}
			}
		}
	}
	

	

	

	//Launching LoadBalancer for WordPress Pods
	resource "kubernetes_service" "wpLb" {
		metadata {
			name   = "wp-svc"
			labels = {
				env     = "Prod"
				Country = "Ind" 
			}
		}  
	

		depends_on = [kubernetes_deployment.wp]
	

		spec {
			type     = "NodePort"
			selector = {
			pod = "wp"
			}
			port {
				port = 80
			}
		}
	}
	

	

	//Output LoadBalancer IP
	output "final_output" {
		value = kubernetes_service.wpLb.spec.0.port.0.node_port
	}