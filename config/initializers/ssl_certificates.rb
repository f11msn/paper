ENV["SSL_CERT_FILE"] ||= "/etc/ssl/cert.pem" if File.exist?("/etc/ssl/cert.pem")
