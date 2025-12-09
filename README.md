# SAP ABAP Developer Boxes

> Docker Compose environment for SAP ABAP 7.52 SP04 Developer Edition  
> Quick bootstrap for ABAP development and training

## Overview

This repository provides a pre-configured Docker Compose setup that eliminates the complexity of manually installing SAP NetWeaver AS ABAP 7.52 SP04 Developer Edition. It handles:

- **System Prerequisites**: Automatic installation of all OS dependencies
- **Kernel Configuration**: SAP kernel parameters (shared memory, semaphores, etc.)
- **System Limits**: ulimits and resource allocation
- **Service Setup**: uuidd, SSH, and other required services
- **Data Persistence**: Volumes for /sapmnt, /sybase, and /usr/sap
- **Network Configuration**: Proper hostname resolution and port mapping

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- At least 8 GB free disk space (100 GB recommended)
- 8 GB RAM minimum (16 GB+ recommended)
- SAP ABAP 7.52 SP04 Developer Edition installation media

### Installation Steps

#### 1. Prepare Installation Files

```bash
# Create directories
mkdir -p downloads scripts

# Extract SAP ABAP 7.52 SP04 installation media to downloads/
# The archive should be from: https://developers.sap.com/trials-downloads.html
unzip TD752SP04*.zip -d downloads/
```

#### 2. Start Docker Container

```bash
# Build and start the container
docker-compose up -d

# Verify container is running
docker-compose ps

# Access the container
docker-compose exec abap-server bash
```

#### 3. Install SAP ABAP

```bash
# Inside the container
cd /home/downloads

# List installation artifacts
ls -la

# Run installation (interactive)
sudo ./install.sh

# Or with options:
# -g   Show SAPINST GUI
# -s   Skip hostname check
# -h   Specify custom hostname
```

#### 4. Complete Installation

The installation will take approximately 20-30 minutes. Upon completion, you should see:

```
Instance on host vhcalnplci started
Installation of NPL successful
```

#### 5. Access the System

After installation:

```bash
# Start SAP services (if not already running)
su - npladm
startsap ALL

# Access the system
# GUI Port: localhost:3200
# Default Clients: 000 and 001
```

## Default Credentials

After installation, the following default users are available:

### Client 000 (System Client)
| User | Password | Role |
|------|----------|------|
| SAP* | Down1oad | SAP Administrator |
| DDIC | Down1oad | Data Dictionary |

### Client 001 (Development Client)
| User | Password | Role |
|------|----------|------|
| SAP* | Down1oad | SAP Administrator |
| DDIC | Down1oad | Data Dictionary |
| DEVELOPER | Down1oad | Developer User |
| BWDEVELOPER | Down1oad | Developer User |

### OS Users (Created During Installation)
| User | Password | Role |
|------|----------|------|
| npladm | [master password] | SAP System Administrator |
| sybnpl | [master password] | Database Administrator |
| sapadm | [master password] | SAP Host Agent |

## Docker Compose Configuration

### Resource Allocation

```yaml
mem_limit: 8g              # 8 GB RAM
memswap_limit: 16g         # 8 GB Swap
cpus: 4.0                  # 4 CPUs
```

Adjust these in `docker-compose.yml` based on your host system:

```bash
# For systems with 16 GB RAM:
mem_limit: 12g
memswap_limit: 20g
cpus: 6.0

# For systems with 32 GB RAM:
mem_limit: 16g
memswap_limit: 32g
cpus: 8.0
```

### Exposed Ports

| Port | Service | Purpose |
|------|---------|----------|
| 3200 | ABAP | GUI HTTP |
| 3201 | ABAP | GUI Secure |
| 3300 | ABAP | Message Server |
| 3301 | ABAP | SAP Router |
| 8000 | ABAP | Web Services |

### Volumes

- `sapmnt`: SAP mount directory (~2 GB)
- `sybase`: Database data (~50 GB)
- `usrsap`: SAP installation (~3 GB)

## Common Tasks

### Starting/Stopping SAP Services

```bash
# Start SAP services
docker-compose exec abap-server su - npladm -c "startsap ALL"

# Stop SAP services
docker-compose exec abap-server su - npladm -c "stopsap ALL"

# Check SAP status
docker-compose exec abap-server su - npladm -c "sapcontrol -nr 00 -function GetProcessList"
```

### Accessing the Container

```bash
# Open interactive shell
docker-compose exec abap-server bash

# Execute command as npladm user
docker-compose exec abap-server su - npladm -c "startsap ALL"

# View container logs
docker-compose logs -f abap-server
```

### License Management

```bash
# Inside the container, as npladm user
su - npladm
startsap ALL

# In another terminal, access SAP GUI
# Connect to localhost:3200
# Login as SAP* with password Down1oad
# Go to transaction SLICENSE
# Note your hardware key

# Download license from:
# https://go.support.sap.com/minisap

# Install the license in SLICENSE transaction
```

## Troubleshooting

### Container won't start

```bash
# Check Docker daemon
docker ps

# View container logs
docker-compose logs

# Check available disk space
df -h
```

### Installation fails

```bash
# Verify prerequisites are installed
docker-compose exec abap-server bash
command -v csh
command -v libaio
command -v uuidd

# Check system parameters
cat /proc/sys/kernel/shmmax
```

### SAP Services won't start

```bash
# Check SAP installation
ls -la /usr/sap/NPL/

# Check permissions
ls -la /sapmnt /sybase /usr/sap

# View SAP startup logs
cat /usr/sap/NPL/D00/work/dev_w0
```

## Production Notes

⚠️ **Important**: This is a development/learning environment only. For production use:

1. **Change master password** in `docker-compose.yml`
2. **Increase resources** based on actual workload
3. **Enable external networking** carefully (firewall rules)
4. **Regular backups** of volumes
5. **Update SAP patches** from SAP support portal
6. **Security hardening** of OS and SAP system

## References

- [SAP ABAP 7.52 SP04 Installation Guide](https://community.sap.com/t5/application-development-and-automation-blog-posts/as-abap-7-52-sp04-developer-edition-concise-installation-guide/ba-p/13389514)
- [Docker Official Documentation](https://docs.docker.com/)
- [SAP NetWeaver Documentation](https://help.sap.com/)

## License

MIT License - See LICENSE file

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## Support

For issues or questions:

1. Check the Troubleshooting section above
2. Review SAP Community forums
3. Consult Docker documentation
4. Open an issue in this repository
