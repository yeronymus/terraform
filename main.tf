module "app_node_test" {
  source         = "./modules/lxc_node"
  vm_id          = 999
  hostname       = "app-node-test"
  ip_address     = "192.168.10.99/24"
  ssh_public_key = var.ssh_public_key
  cores          = 2
  memory         = 2048
  disk_size      = 8
}

output "test_container_ip" {
  value = module.app_node_test.container_ip
}

output "test_container_password" {
  value     = module.app_node_test.root_password
  sensitive = true
}
