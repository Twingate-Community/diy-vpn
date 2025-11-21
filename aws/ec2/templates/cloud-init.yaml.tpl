#cloud-config
# Twingate Connector Installation via Official Method
# Based on: https://docs.twingate.com/docs/connector-deployment-guides

apt:
  sources:
    twingate:
      source: deb [trusted=true] https://packages.twingate.com/apt/ /

package_update: true
package_upgrade: true

packages:
  - twingate-connector
  - htop
  - curl

write_files:
- path: /etc/twingate/connector.conf
  permissions: 0600
  content: |
    TWINGATE_ACCESS_TOKEN=${access_token}
    TWINGATE_REFRESH_TOKEN=${refresh_token}
    TWINGATE_NETWORK=${network}
    TWINGATE_LABEL_DEPLOYED_BY=aws_ec2_vpn
    TWINGATE_LABEL_REGION=${region}
    TWINGATE_LABEL_ENVIRONMENT=${environment}
    TWINGATE_LABEL_CONNECTOR=${connector_name}

- path: /etc/apt/apt.conf.d/50unattended-upgrades
  append: true
  content: |
    Unattended-Upgrade::Origins-Pattern {
        site=packages.twingate.com;
    };

- path: /etc/systemd/system/twingate-connector.service.d/override.conf
  permissions: 0644
  content: |
    [Service]
    # Restart policy for reliability
    Restart=always
    RestartSec=10
    
    # Resource limits
    LimitNOFILE=65536
    
    # Logging
    StandardOutput=journal
    StandardError=journal

runcmd:
  # Enable and start the Twingate connector service
  - systemctl daemon-reload
  - systemctl enable twingate-connector
  - systemctl start twingate-connector
  
  # Wait a moment for service to start
  - sleep 5
  
  # Check service status (for logging)
  - systemctl status twingate-connector --no-pager || true
  
  # Set up log rotation for connector logs
  - |
    cat > /etc/logrotate.d/twingate-connector << 'EOF'
    /var/log/twingate/*.log {
        daily
        missingok
        rotate 7
        compress
        notifempty
        create 0644 root root
        postrotate
            systemctl reload twingate-connector || true
        endscript
    }
    EOF

# Set timezone
timezone: UTC

# Configure automatic security updates
package_reboot_if_required: true