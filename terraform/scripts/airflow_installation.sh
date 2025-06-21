#!/bin/bash

# Airflow Installation Script
# This script installs Apache Airflow with commonly used extras on Linux

# Exit immediately if any command fails
set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root or with sudo"
  exit 1
fi

# Configuration variables
AIRFLOW_VERSION="2.8.1"
PYTHON_VERSION="3.10"
AIRFLOW_HOME="${AIRFLOW_HOME:-/opt/airflow}"
AIRFLOW_USER="airflow"
AIRFLOW_GROUP="airflow"
AIRFLOW_EXTRAS="celery,postgres,redis,amazon,ssh,slack"

# Set AIRFLOW_HOME environment variable
export AIRFLOW_HOME

# Update package lists
echo "Updating package lists..."
apt-get update

# Install required system dependencies
echo "Installing system dependencies..."
apt-get install -y --no-install-recommends \
    build-essential \
    python${PYTHON_VERSION}-dev \
    python3-pip \
    python3-wheel \
    python3-venv \
    libssl-dev \
    libffi-dev \
    libpq-dev \
    curl \
    git \
    wget \
    unzip \
    freetds-dev \
    libkrb5-dev \
    libsasl2-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libgeos-dev \
    libsnappy-dev \
    libbz2-dev

# Create Airflow user and group if they don't exist
if ! id -u ${AIRFLOW_USER} >/dev/null 2>&1; then
  echo "Creating Airflow user and group..."
  groupadd ${AIRFLOW_GROUP}
  useradd -g ${AIRFLOW_GROUP} -d ${AIRFLOW_HOME} -m -s /bin/bash ${AIRFLOW_USER}
fi

# Create and set permissions for Airflow directory
echo "Setting up Airflow directory..."
mkdir -p ${AIRFLOW_HOME}
chown -R ${AIRFLOW_USER}:${AIRFLOW_GROUP} ${AIRFLOW_HOME}

# Install Airflow with pip as the airflow user
echo "Installing Apache Airflow ${AIRFLOW_VERSION} with extras: ${AIRFLOW_EXTRAS}..."
sudo -u ${AIRFLOW_USER} bash << EOF
# Set AIRFLOW_HOME for the user session
export AIRFLOW_HOME=${AIRFLOW_HOME}

# Upgrade pip
python3 -m pip install --upgrade pip

# Install Airflow with specified extras
python3 -m pip install "apache-airflow[${AIRFLOW_EXTRAS}]==${AIRFLOW_VERSION}" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
EOF

# Initialize the Airflow database
echo "Initializing Airflow database..."
sudo -u ${AIRFLOW_USER} bash << EOF
export AIRFLOW_HOME=${AIRFLOW_HOME}
airflow db init
EOF

# Create default connections (example for PostgreSQL)
# Uncomment and modify as needed
# sudo -u ${AIRFLOW_USER} bash << EOF
# export AIRFLOW_HOME=${AIRFLOW_HOME}
# airflow connections add 'postgres_default' \
#     --conn-type 'postgres' \
#     --conn-host 'localhost' \
#     --conn-login 'airflow' \
#     --conn-password 'airflow' \
#     --conn-port '5432' \
#     --conn-schema 'airflow'
# EOF

# Create a systemd service file for Airflow webserver
echo "Creating systemd service for Airflow webserver..."
cat > /etc/systemd/system/airflow-webserver.service << EOF
[Unit]
Description=Airflow webserver daemon
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
User=${AIRFLOW_USER}
Group=${AIRFLOW_GROUP}
Type=simple
ExecStart=/usr/local/bin/airflow webserver
Restart=on-failure
RestartSec=5s
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="AIRFLOW_HOME=${AIRFLOW_HOME}"

[Install]
WantedBy=multi-user.target
EOF

# Create a systemd service file for Airflow scheduler
echo "Creating systemd service for Airflow scheduler..."
cat > /etc/systemd/system/airflow-scheduler.service << EOF
[Unit]
Description=Airflow scheduler daemon
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
User=${AIRFLOW_USER}
Group=${AIRFLOW_GROUP}
Type=simple
ExecStart=/usr/local/bin/airflow scheduler
Restart=always
RestartSec=5s
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="AIRFLOW_HOME=${AIRFLOW_HOME}"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
echo "Enabling and starting Airflow services..."
systemctl daemon-reload
systemctl enable airflow-webserver.service
systemctl enable airflow-scheduler.service
systemctl start airflow-webserver.service
systemctl start airflow-scheduler.service

# Print installation summary
echo ""
echo "Airflow installation complete!"
echo "-----------------------------"
echo "Airflow version: ${AIRFLOW_VERSION}"
echo "Airflow home: ${AIRFLOW_HOME}"
echo "Airflow user: ${AIRFLOW_USER}"
echo "Python version: ${PYTHON_VERSION}"
echo ""
echo "Airflow webserver should be running on: http://localhost:8080"
echo ""
echo "To create an admin user, run:"
echo "sudo -u ${AIRFLOW_USER} airflow users create \\"
echo "    --username admin --password admin \\"
echo "    --firstname First --lastname Last \\"
echo "    --role Admin --email admin@example.com"
echo ""
echo "To check service status:"
echo "systemctl status airflow-webserver.service"
echo "systemctl status airflow-scheduler.service"