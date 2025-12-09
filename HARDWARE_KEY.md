# SAP ABAP Hardware Key Automation

## Overview

This documentation covers the automated hardware key management system for SAP ABAP 7.52 SP04 running in Docker containers. Hardware keys are essential licensing credentials that SAP systems require for operation.

## What is a Hardware Key?

A hardware key (also called license key) is a unique identifier bound to your SAP system's hardware configuration. It includes:
- System ID (SID)
- Host name
- Database type
- Kernel release
- CPU and memory configuration

## Quick Start

### 1. Generate Hardware Key

```bash
./scripts/setup-hwkey.sh generate
```

This command:
- Creates the `config/` directory if it doesn't exist
- Generates a new hardware key file with timestamp
- Stores the key in `config/hwkeys/hwkey_YYYYMMDD_HHMMSS.key`

### 2. Configure Settings (Optional)

```bash
cp config/hwkey.conf.template config/hwkey.conf
vim config/hwkey.conf  # Edit for your environment
```

Key configuration options:
- `SID`: System ID (default: NPL)
- `SYSTEM_NUMBER`: Instance number (default: 00)
- `CONTAINER_NAME`: Docker container name (default: abap-server)
- `AUTO_RENEW`: Enable automatic key renewal (default: true)

### 3. Install Hardware Key

```bash
./scripts/setup-hwkey.sh install
```

This command:
- Copies the latest generated key to the container
- Sets proper file permissions (600)
- Places key at `/usr/sap/npl/SYS/etc/license/hwkey`

### 4. Verify Installation

```bash
./scripts/setup-hwkey.sh verify
```

Checks:
- Key file exists in container
- Key file has correct permissions
- Key content is readable

### 5. Check Status

```bash
./scripts/setup-hwkey.sh status
```

Displays:
- Number of generated keys
- Latest key files
- Container status
- Installation verification

## Complete Setup Workflow

For a one-step setup:

```bash
# Complete hardware key setup
./scripts/setup-hwkey.sh setup
```

This runs all steps in sequence:
1. Creates configuration
2. Generates key
3. Installs key in container
4. Verifies installation

## Configuration Reference

Edit `config/hwkey.conf` to customize:

### System Identification
```ini
SID=NPL                          # System ID
SYSTEM_NUMBER=00                 # Instance number
HOST_NAME=sapdevboxes            # Hostname
IP_ADDRESS=localhost             # IP address
SYSTEM_TYPE=ABAP                 # System type
```

### Database Configuration
```ini
DB_SID=NPL                       # Database SID
DATABASE_USER=sapadm             # SAP admin user
DB_HOST=localhost                # Database host
DB_PORT=39013                    # Database port (HANA)
DBI=HANADB                       # Database interface
```

### License Settings
```ini
LICENSE_KEY_PATH=/usr/sap/npl/SYS/etc/license
LICENSE_KEY_FILE=hwkey.sap
BACKUP_KEY_PATH=/usr/sap/npl/backup/license
```

### Automatic Renewal
```ini
AUTO_RENEW=true                  # Enable auto-renewal
RENEW_BEFORE_EXPIRY_DAYS=30      # Renew before expiry
MAX_RETRIES=3                    # Retry attempts
RETRY_INTERVAL_SECONDS=10        # Retry interval
```

### Docker Settings
```ini
CONTAINER_NAME=abap-server       # Container name
AUTO_COPY_TO_CONTAINER=true      # Auto-copy key
KEY_FILE_PERMISSIONS=600         # File permissions
```

## Script Commands

### Generate
```bash
./scripts/setup-hwkey.sh generate
```
Generates a new hardware key based on system information.

**Output:**
- Creates `config/hwkeys/` directory
- Saves key file with timestamp
- Returns file path

### Install
```bash
./scripts/setup-hwkey.sh install
```
Installs the latest generated key into the container.

**Requirements:**
- Container must be running
- Key must exist in `config/hwkeys/`

**Process:**
1. Finds latest key file
2. Generates key if none exist
3. Copies to container
4. Sets permissions

### Verify
```bash
./scripts/setup-hwkey.sh verify
```
Verifies hardware key installation in container.

**Checks:**
- Key file exists
- File permissions are correct
- File is readable

**Returns:**
- 0 = Success
- 1 = Key not found or error

### Status
```bash
./scripts/setup-hwkey.sh status
```
Shows current hardware key status.

**Displays:**
- Number of generated keys
- Recent key files
- Container status
- Verification results

### Setup (Complete)
```bash
./scripts/setup-hwkey.sh setup
```
Performs complete setup workflow:
1. Creates configuration
2. Generates key
3. Installs key
4. Verifies installation

## Troubleshooting

### Container not found
```
ERROR: Container 'abap-server' is not running
```
**Solution:**
```bash
docker-compose up -d
./scripts/setup-hwkey.sh install
```

### No hardware keys generated
```
ERROR: No hardware keys found
```
**Solution:**
```bash
./scripts/setup-hwkey.sh generate
./scripts/setup-hwkey.sh install
```

### Permission denied
```
ERROR: Permission denied
```
**Solution:**
```bash
chmod +x ./scripts/setup-hwkey.sh
./scripts/setup-hwkey.sh setup
```

### Key installation failed
```
WARNING: Direct copy failed
```
Script automatically retries with alternative method (docker exec + tee)

## Integration with Installation

Hardware key setup is automatically integrated into the main installation:

```bash
# From README.md installation steps
mkdir -p downloads scripts
cd downloads
unzip TD752SP04_*.zip -d .
cd ..

# Start container
docker-compose up -d

# Hardware key is automatically set up if AUTO_SETUP_HWKEY_ON_INSTALL=true
./scripts/setup-hwkey.sh setup
```

## Automatic Renewal

When `AUTO_RENEW=true` in configuration:

1. Script monitors key expiry
2. Generates new key `RENEW_BEFORE_EXPIRY_DAYS` before expiry
3. Automatically installs new key
4. Sends notifications if enabled
5. Maintains backup of old keys

## File Structure

```
sapdevboxes/
├── scripts/
│   ├── install-abap.sh          # Main installation
│   ├── setup-hwkey.sh           # Hardware key script
│   └── hwkey.conf.template      # Config template
├── config/
│   ├── hwkey.conf               # Your configuration
│   └── hwkeys/
│       ├── hwkey_20241209_143022.key
│       └── hwkey_20241209_153045.key
├── docker-compose.yml
└── README.md
```

## Key Locations

**Host System:**
- Generated keys: `./config/hwkeys/`
- Configuration: `./config/hwkey.conf`
- Logs: `/var/log/sap/hwkey/`

**Inside Container:**
- Active key: `/usr/sap/npl/SYS/etc/license/hwkey`
- Backups: `/usr/sap/npl/backup/license/`
- Archive: `/usr/sap/npl/archive/license/`

## Security Considerations

1. **File Permissions:**
   - Key files: 600 (read/write by owner only)
   - Config files: 600 (read/write by owner only)

2. **Backup:**
   - Always keep backups of working keys
   - Store in secure location

3. **Encryption:**
   - Keys are stored in plain text by default
   - Set `ENCRYPTED_KEY=true` to enable encryption

4. **Expiry Management:**
   - Monitor key expiry dates
   - Enable auto-renewal for production systems
   - Set up notifications for manual renewal

## Advanced Usage

### Custom Hardware Key

For special configurations, edit the key generation logic in `setup-hwkey.sh`

### Multi-System Setup

For multiple SAP instances:

```bash
# Create separate configs
cp config/hwkey.conf.template config/hwkey_dev.conf
cp config/hwkey.conf.template config/hwkey_prod.conf

# Setup each system
CONTAINER_NAME=dev-server ./scripts/setup-hwkey.sh setup
CONTAINER_NAME=prod-server ./scripts/setup-hwkey.sh setup
```

### Validation

After installation, verify key is recognized:

```bash
docker-compose exec abap-server sapcontrol -nr 00 -function GetSystemInstanceList
```

## Support

For issues related to:
- **Hardware keys:** Check `config/hwkey.conf` settings
- **Container connectivity:** Verify `docker ps` shows container running
- **File permissions:** Ensure scripts have execute permission
- **SAP system:** Refer to SAP NetWeaver documentation

## References

- [SAP NetWeaver Hardware Keys](https://help.sap.com)
- [Docker Compose Documentation](https://docs.docker.com/compose)
- [SAP ABAP 7.52 Installation Guide](https://help.sap.com)

## Version History

- **v1.0** (2024-12-09) - Initial hardware key automation release
  - Automatic key generation
  - Container-based installation
  - Configuration templates
  - Status monitoring and verification
