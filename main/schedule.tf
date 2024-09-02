resource "google_compute_resource_policy" "daily_schedule" {
  name   = "vm-daily-schedule"
  region = var.region
  description = "Start and stop VM instances during weekdays"

  instance_schedule_policy {
    vm_start_schedule {
      schedule = "45 7 * * 1-5"
    }
    vm_stop_schedule {
      schedule = "15 21 * * 1-5"
    }
    time_zone = "Africa/Casablanca"
  }
}