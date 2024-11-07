c = get_config()

# this is totally unsafe, do NOT expose to 0.0.0.0 whatsoever!

c.ServerApp.token = ""
c.ServerApp.password_required = False
c.ServerApp.quit_button = False
c.ServerApp.shutdown_no_activity_timeout = 0
