#!/usr/bin/env bash
set -euo pipefail

# Unified helper to run a Nock mining node
# - Loads .env if present for defaults
# - Auto-detects sensible mining threads
# - Supports fakenet/mainnet toggles
# - Validates mining key inputs

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR%/scripts}"

if [[ -f "${REPO_ROOT}/.env" ]]; then
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/.env"
fi

if [[ -z "${RUST_LOG:-}" ]]; then
  export RUST_LOG="info,nockapp=info,nockchain=info"
fi
export MINIMAL_LOG_FORMAT="${MINIMAL_LOG_FORMAT:-1}"

usage() {
  cat <<'USAGE'
Usage: scripts/mine_nock.sh [options]

Options:
  --mining-pubkey B58        Mining pubkey (Base58). Env: MINING_PUBKEY
  --mining-key-adv SPEC      Advanced config (repeatable). Format: share,m:key1,key2
  --threads N                Mining threads. Default: (cpus - 2) min 1
  --fakenet                  Enable fakenet mode (env FAKENET=1)
  --fakenet-pow-len N        Fakenet PoW length (power of 2). Env: FAKENET_POW_LEN
  --fakenet-log-difficulty D Fakenet log difficulty. Env: FAKENET_LOG_DIFFICULTY
  --grpc-address URL         Private gRPC bind, e.g. http://127.0.0.1:5555
  --bind ADDR                P2P bind multiaddr (repeatable)
  --peer ADDR                P2P peer multiaddr (repeatable)
  --force-peer ADDR          Force-connect peer (repeatable)
  --no-default-peers         Disable dialing default peers
  --public-grpc ADDR         Public gRPC bind socket addr, default 127.0.0.1:5555
  --help                     Show this help

Examples:
  MINING_PUBKEY=... scripts/mine_nock.sh --threads 8
  scripts/mine_nock.sh --fakenet --grpc-address http://127.0.0.1:5555 \
      --bind /ip4/127.0.0.1/udp/3006/quic-v1 \
      --mining-pubkey YOUR_B58_PUBKEY
USAGE
}

get_cpu_count() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
  elif [[ "${OSTYPE:-}" == darwin* ]] && command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.logicalcpu
  else
    echo 4
  fi
}

# Defaults
FAKENET_FLAG="${FAKENET:-}"  # empty means disabled
MINING_PUBKEY_ARG="${MINING_PUBKEY:-}"
THREADS=""
FAKENET_POW_LEN_ARG="${FAKENET_POW_LEN:-}"
FAKENET_LOG_DIFFICULTY_ARG="${FAKENET_LOG_DIFFICULTY:-}"
GRPC_ADDRESS_ARG="${GRPC_ADDRESS:-}"
PUBLIC_GRPC_ADDR_ARG="${PUBLIC_GRPC_ADDR:-}"
BIND_ARGS=()
PEER_ARGS=()
FORCE_PEER_ARGS=()
ADVANCED_MINING_ARGS=()
NO_DEFAULT_PEERS_FLAG=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mining-pubkey)
      shift; MINING_PUBKEY_ARG="${1:-}"; [[ -n "$MINING_PUBKEY_ARG" ]] || { echo "missing value for --mining-pubkey" >&2; exit 1; } ;;
    --mining-key-adv)
      shift; ADVANCED_MINING_ARGS+=("${1:-}"); [[ -n "${ADVANCED_MINING_ARGS[-1]}" ]] || { echo "missing value for --mining-key-adv" >&2; exit 1; } ;;
    --threads)
      shift; THREADS="${1:-}"; [[ "$THREADS" =~ ^[0-9]+$ ]] || { echo "--threads must be a number" >&2; exit 1; } ;;
    --fakenet)
      FAKENET_FLAG=1 ;;
    --fakenet-pow-len)
      shift; FAKENET_POW_LEN_ARG="${1:-}" ;;
    --fakenet-log-difficulty)
      shift; FAKENET_LOG_DIFFICULTY_ARG="${1:-}" ;;
    --grpc-address)
      shift; GRPC_ADDRESS_ARG="${1:-}" ;;
    --public-grpc)
      shift; PUBLIC_GRPC_ADDR_ARG="${1:-}" ;;
    --bind)
      shift; BIND_ARGS+=("${1:-}") ;;
    --peer)
      shift; PEER_ARGS+=("${1:-}") ;;
    --force-peer)
      shift; FORCE_PEER_ARGS+=("${1:-}") ;;
    --no-default-peers)
      NO_DEFAULT_PEERS_FLAG=1 ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift || true
done

# Validate nockchain existence
if ! command -v nockchain >/dev/null 2>&1; then
  echo "Error: 'nockchain' binary not found in PATH. Build it with:\n  cargo build --release -p nockchain\nThen add 'target/release' to your PATH or install accordingly." >&2
  exit 1
fi

# Determine threads if not provided
if [[ -z "$THREADS" ]]; then
  total_threads=$(get_cpu_count)
  threads_calc=$(( total_threads > 2 ? total_threads - 2 : 1 ))
  THREADS="$threads_calc"
fi

# Mining key validation: require pubkey or advanced config
if [[ -z "$MINING_PUBKEY_ARG" && ${#ADVANCED_MINING_ARGS[@]} -eq 0 ]]; then
  echo "Error: Provide --mining-pubkey or at least one --mining-key-adv.\nYou can also set MINING_PUBKEY in .env" >&2
  exit 1
fi

# Build command
cmd=("nockchain" "--mine" "--num-threads" "$THREADS")

# Fakenet toggles
if [[ -n "$FAKENET_FLAG" ]]; then
  cmd+=("--fakenet")
  if [[ -n "$FAKENET_POW_LEN_ARG" ]]; then
    cmd+=("--fakenet-pow-len" "$FAKENET_POW_LEN_ARG")
  fi
  if [[ -n "$FAKENET_LOG_DIFFICULTY_ARG" ]]; then
    cmd+=("--fakenet-log-difficulty" "$FAKENET_LOG_DIFFICULTY_ARG")
  fi
fi

# Mining keys
if [[ -n "$MINING_PUBKEY_ARG" ]]; then
  cmd+=("--mining-pubkey" "$MINING_PUBKEY_ARG")
fi
for spec in "${ADVANCED_MINING_ARGS[@]:-}"; do
  [[ -n "$spec" ]] || continue
  cmd+=("--mining-key-adv" "$spec")
done

# Networking
if [[ -n "$GRPC_ADDRESS_ARG" ]]; then
  cmd+=("--grpc-address" "$GRPC_ADDRESS_ARG")
fi
if [[ -n "$PUBLIC_GRPC_ADDR_ARG" ]]; then
  cmd+=("--bind-public-grpc-addr" "$PUBLIC_GRPC_ADDR_ARG")
fi
for addr in "${BIND_ARGS[@]:-}"; do
  cmd+=("--bind" "$addr")
done
for addr in "${PEER_ARGS[@]:-}"; do
  cmd+=("--peer" "$addr")
done
for addr in "${FORCE_PEER_ARGS[@]:-}"; do
  cmd+=("--force-peer" "$addr")
done
if [[ -n "$NO_DEFAULT_PEERS_FLAG" ]]; then
  cmd+=("--no-default-peers")
fi

# Display and run
echo "Starting nockchain miner with $THREADS mining threads..."
echo "Command: ${cmd[*]}"
exec "${cmd[@]}"
