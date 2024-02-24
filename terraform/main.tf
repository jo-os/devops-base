############################################
resource "yandex_compute_instance" "vm1" {
  name        = "vm1"
  platform_id = "standard-v3"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8svvs3unvqn83thrdk"
      size = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    user-data   = "${file("./user_data.sh")}"
  }
}


resource "yandex_compute_instance" "vm2" {
  name        = "vm2"
  platform_id = "standard-v3"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8svvs3unvqn83thrdk"
      size = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    user-data   = "${file("./user_data.sh")}"
  }
}

############################################
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}
############################################
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = yandex_vpc_network.network-1.id
}
