#!/bin/bash
#
# Ansible Playbook Execution Script
# Enhanced with better error handling, reporting, and options
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default values
ENVIRONMENT="production"
PLAYBOOK="playbook.yml"
INVENTORY="inventory.ini"
TAGS=""
LIMIT=""
CHECK_MODE=""
VERBOSE=""
DIFF_MODE="--diff"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -e, --env ENV          Environment to use (default: production)
    -p, --playbook FILE    Playbook to run (default: playbook.yml)
    -i, --inventory FILE   Inventory file (default: inventory.ini)
    -t, --tags TAGS        Only run plays and tasks tagged with these values
    -l, --limit HOSTS      Limit selected hosts to an additional pattern
    -c, --check           Don't make any changes; instead, try to predict changes
    -v, --verbose         Increase verbosity (-vvv for more)
    -h, --help            Display this help message
    --no-diff             Don't show diffs
    
EXAMPLES:
    $0                                    # Run with defaults
    $0 -e staging -t security             # Run only security tasks in staging
    $0 -c -l "web*"                      # Check mode on web servers only
    $0 -vvv -t debug                     # Very verbose debug run
EOF
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -p|--playbook)
            PLAYBOOK="$2"
            shift 2
            ;;
        -i|--inventory)
            INVENTORY="$2"
            shift 2
            ;;
        -t|--tags)
            TAGS="--tags $2"
            shift 2
            ;;
        -l|--limit)
            LIMIT="--limit $2"
            shift 2
            ;;
        -c|--check)
            CHECK_MODE="--check"
            shift
            ;;
        -v|--verbose)
            VERBOSE="${VERBOSE}v"
            shift
            ;;
        --no-diff)
            DIFF_MODE=""
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Load environment variables
ENV_FILE=".env"
if [[ "$ENVIRONMENT" != "production" ]]; then
    ENV_FILE=".env.${ENVIRONMENT}"
fi

if [[ -f "$ENV_FILE" ]]; then
    echo -e "${GREEN}Loading environment from: ${ENV_FILE}${NC}"
    set -a
    source "$ENV_FILE"
    set +a
else
    echo -e "${RED}Environment file not found: ${ENV_FILE}${NC}"
    exit 1
fi

# Validate files exist
for file in "$PLAYBOOK" "$INVENTORY"; do
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}File not found: $file${NC}"
        exit 1
    fi
done

# Create directories
mkdir -p logs reports backups

# Generate timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="logs/ansible_run_${TIMESTAMP}.log"
JSON_FILE="logs/ansible_run_${TIMESTAMP}.json"
REPORT_FILE="reports/ansible_report_${TIMESTAMP}.html"

# Display execution plan
echo -e "${GREEN}=== Ansible Execution Plan ===${NC}"
echo "Environment: $ENVIRONMENT"
echo "Playbook: $PLAYBOOK"
echo "Inventory: $INVENTORY"
echo "Timestamp: $TIMESTAMP"
[[ -n "$TAGS" ]] && echo "Tags: $TAGS"
[[ -n "$LIMIT" ]] && echo "Limit: $LIMIT"
[[ -n "$CHECK_MODE" ]] && echo -e "${YELLOW}Running in CHECK MODE - no changes will be made${NC}"
echo "----------------------------------------"

# Ask for confirmation in production
if [[ "$ENVIRONMENT" == "production" && -z "$CHECK_MODE" ]]; then
    read -p "You are about to run against PRODUCTION. Continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Build ansible-playbook command
ANSIBLE_CMD="ansible-playbook"
[[ -n "$VERBOSE" ]] && ANSIBLE_CMD="$ANSIBLE_CMD -${VERBOSE}"
ANSIBLE_CMD="$ANSIBLE_CMD -i $INVENTORY $PLAYBOOK"
[[ -n "$TAGS" ]] && ANSIBLE_CMD="$ANSIBLE_CMD $TAGS"
[[ -n "$LIMIT" ]] && ANSIBLE_CMD="$ANSIBLE_CMD $LIMIT"
[[ -n "$CHECK_MODE" ]] && ANSIBLE_CMD="$ANSIBLE_CMD $CHECK_MODE"
[[ -n "$DIFF_MODE" ]] && ANSIBLE_CMD="$ANSIBLE_CMD $DIFF_MODE"

# Additional Ansible options
export ANSIBLE_STDOUT_CALLBACK=json
export ANSIBLE_LOAD_CALLBACK_PLUGINS=true

# Start execution
echo -e "${GREEN}Starting Ansible playbook execution at $(date)${NC}"
echo "Command: $ANSIBLE_CMD"
echo "----------------------------------------"

# Run Ansible and capture both regular and JSON output
{
    # First run with regular output for the log
    export ANSIBLE_STDOUT_CALLBACK=yaml
    eval "$ANSIBLE_CMD" 2>&1 | tee "${LOG_FILE}"
    ANSIBLE_STATUS=${PIPESTATUS[0]}
    
    # Then run with JSON output for parsing (in check mode to be safe)
    export ANSIBLE_STDOUT_CALLBACK=json
    eval "$ANSIBLE_CMD --check" > "${JSON_FILE}" 2>&1 || true
} 

# Parse results
PLAY_COUNT=$(grep -c "PLAY \[" "${LOG_FILE}" || echo "0")
TASK_COUNT=$(grep -c "TASK \[" "${LOG_FILE}" || echo "0")
OK_COUNT=$(grep -oE "ok=[0-9]+" "${LOG_FILE}" | tail -1 | cut -d= -f2 || echo "0")
CHANGED_COUNT=$(grep -oE "changed=[0-9]+" "${LOG_FILE}" | tail -1 | cut -d= -f2 || echo "0")
FAILED_COUNT=$(grep -oE "failed=[0-9]+" "${LOG_FILE}" | tail -1 | cut -d= -f2 || echo "0")
UNREACHABLE_COUNT=$(grep -oE "unreachable=[0-9]+" "${LOG_FILE}" | tail -1 | cut -d= -f2 || echo "0")

# Generate enhanced HTML report
echo -e "${YELLOW}Generating HTML report...${NC}"
cat >"${REPORT_FILE}" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ansible Report - ${TIMESTAMP}</title>
    <style>
        :root {
            --success: #28a745;
            --warning: #ffc107;
            --danger: #dc3545;
            --info: #17a2b8;
            --dark: #343a40;
            --light: #f8f9fa;
        }
        
        * { box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: var(--light);
            color: var(--dark);
            line-height: 1.6;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        h1 { 
            color: var(--dark);
            border-bottom: 3px solid var(--info);
            padding-bottom: 10px;
        }
        
        h2 {
            color: var(--dark);
            margin-top: 30px;
            border-bottom: 1px solid #dee2e6;
            padding-bottom: 10px;
        }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        
        .card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .card h3 {
            margin: 0 0 10px 0;
            color: var(--dark);
            font-size: 1.1rem;
        }
        
        .card .value {
            font-size: 2rem;
            font-weight: bold;
        }
        
        .success { color: var(--success); }
        .warning { color: var(--warning); }
        .danger { color: var(--danger); }
        .info { color: var(--info); }
        
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            color: white;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .status-success { background-color: var(--success); }
        .status-failure { background-color: var(--danger); }
        
        pre {
            background-color: #f4f4f4;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 15px;
            overflow-x: auto;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
            line-height: 1.4;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #f8f9fa;
            font-weight: bold;
            color: var(--dark);
        }
        
        tr:hover { background-color: #f8f9fa; }
        
        .log-output {
            max-height: 600px;
            overflow-y: auto;
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 20px;
            border-radius: 4px;
            font-family: 'Consolas', 'Monaco', monospace;
        }
        
        .timestamp { 
            color: #666;
            font-size: 0.9rem;
        }
        
        @media print {
            .no-print { display: none; }
            pre { max-height: none; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 Ansible Execution Report</h1>
        
        <div class="status-badge $([ $ANSIBLE_STATUS -eq 0 ] && echo 'status-success' || echo 'status-failure')">
            $([ $ANSIBLE_STATUS -eq 0 ] && echo '✓ SUCCESS' || echo '✗ FAILURE')
        </div>
        
        <h2>📊 Execution Summary</h2>
        <div class="summary">
            <div class="card">
                <h3>Environment</h3>
                <div class="value info">${ENVIRONMENT}</div>
            </div>
            <div class="card">
                <h3>Duration</h3>
                <div class="value">$(grep "Playbook run took" "${LOG_FILE}" | awk '{print $4, $5, $6}' || echo "N/A")</div>
            </div>
            <div class="card">
                <h3>Plays</h3>
                <div class="value">${PLAY_COUNT}</div>
            </div>
            <div class="card">
                <h3>Tasks</h3>
                <div class="value">${TASK_COUNT}</div>
            </div>
        </div>
        
        <h2>📈 Task Results</h2>
        <div class="summary">
            <div class="card">
                <h3>OK</h3>
                <div class="value success">${OK_COUNT}</div>
            </div>
            <div class="card">
                <h3>Changed</h3>
                <div class="value warning">${CHANGED_COUNT}</div>
            </div>
            <div class="card">
                <h3>Failed</h3>
                <div class="value danger">${FAILED_COUNT}</div>
            </div>
            <div class="card">
                <h3>Unreachable</h3>
                <div class="value danger">${UNREACHABLE_COUNT}</div>
            </div>
        </div>
        
        <h2>ℹ️ Execution Details</h2>
        <table>
            <tr>
                <th>Property</th>
                <th>Value</th>
            </tr>
            <tr>
                <td>Date & Time</td>
                <td class="timestamp">$(date)</td>
            </tr>
            <tr>
                <td>Playbook</td>
                <td><code>${PLAYBOOK}</code></td>
            </tr>
            <tr>
                <td>Inventory</td>
                <td><code>${INVENTORY}</code></td>
            </tr>
            <tr>
                <td>User</td>
                <td>${USER}@$(hostname)</td>
            </tr>
            <tr>
                <td>Command</td>
                <td><code>${ANSIBLE_CMD}</code></td>
            </tr>
            <tr>
                <td>Log File</td>
                <td><code>${LOG_FILE}</code></td>
            </tr>
        </table>
        
        <h2>🖥️ Target Hosts</h2>
        <pre>$(ansible-inventory -i "${INVENTORY}" --list --yaml | head -50)</pre>
        
        <h2>📝 Execution Log</h2>
        <div class="log-output">
            <pre>$(cat "${LOG_FILE}" | sed 's/\x1b\[[0-9;]*m//g')</pre>
        </div>
        
        <hr style="margin-top: 50px;">
        <p class="timestamp">
            Generated on $(date) by Ansible Basic Server Configuration<br>
            <small>Report: ${REPORT_FILE}</small>
        </p>
    </div>
</body>
</html>
EOF

# Generate summary file
SUMMARY_FILE="reports/summary_${TIMESTAMP}.txt"
cat >"${SUMMARY_FILE}" <<EOF
ANSIBLE EXECUTION SUMMARY
========================
Date: $(date)
Environment: ${ENVIRONMENT}
Status: $([ $ANSIBLE_STATUS -eq 0 ] && echo 'SUCCESS' || echo 'FAILURE')
Exit Code: ${ANSIBLE_STATUS}

STATISTICS:
- Plays: ${PLAY_COUNT}
- Tasks: ${TASK_COUNT}
- OK: ${OK_COUNT}
- Changed: ${CHANGED_COUNT}
- Failed: ${FAILED_COUNT}
- Unreachable: ${UNREACHABLE_COUNT}

FILES:
- Log: ${LOG_FILE}
- Report: ${REPORT_FILE}
- JSON: ${JSON_FILE}

COMMAND:
${ANSIBLE_CMD}
EOF

# Show completion message
echo ""
echo "========================================"
if [ $ANSIBLE_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ Execution completed successfully!${NC}"
else
    echo -e "${RED}✗ Execution failed with status: $ANSIBLE_STATUS${NC}"
fi
echo "========================================"
echo -e "📄 Log saved to: ${YELLOW}${LOG_FILE}${NC}"
echo -e "📊 Report saved to: ${YELLOW}${REPORT_FILE}${NC}"
echo -e "📋 Summary saved to: ${YELLOW}${SUMMARY_FILE}${NC}"

# Open report if in desktop environment
if [[ -n "${DISPLAY:-}" ]] && command -v xdg-open >/dev/null 2>&1; then
    echo -e "\n${GREEN}Opening report in browser...${NC}"
    xdg-open "${REPORT_FILE}" 2>/dev/null || true
elif [[ "$OSTYPE" == "darwin"* ]] && command -v open >/dev/null 2>&1; then
    open "${REPORT_FILE}"
fi

# Cleanup old logs (optional)
if [[ "${CLEANUP_OLD_LOGS:-false}" == "true" ]]; then
    echo -e "\n${YELLOW}Cleaning up logs older than 30 days...${NC}"
    find logs reports -name "*.log" -o -name "*.html" -o -name "*.json" -mtime +30 -delete
fi

exit $ANSIBLE_STATUS
