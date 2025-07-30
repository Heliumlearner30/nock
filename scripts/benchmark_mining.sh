#!/bin/bash

# Mining Performance Benchmark Script
set -e

echo "=== Mining Performance Benchmark ==="

# Compile pre-optimization version
echo "1. Compiling pre-optimization version..."
git stash
cargo build --release --bin nockchain
mv target/release/nockchain target/release/nockchain-original

# Compile post-optimization version
echo "2. Compiling post-optimization version..."
git stash pop
cargo build --release --bin nockchain
mv target/release/nockchain target/release/nockchain-optimized

# Memory usage monitoring function
monitor_memory() {
    local pid=$1
    local log_file=$2
    while kill -0 $pid 2>/dev/null; do
        local mem_usage=$(ps -o rss= -p $pid 2>/dev/null || echo "0")
        echo "$(date +%s),$mem_usage" >> $log_file
        sleep 1
    done
}

# Test function
run_mining_test() {
    local binary=$1
    local test_name=$2
    local duration=300  # 5 minute test
    
    echo "Starting test: $test_name"
    
    # Start mining node
    $binary --config test-config.json --mine --mining-threads 4 &
    local miner_pid=$!
    
    # Monitor memory usage
    local mem_log="memory_${test_name}.csv"
    monitor_memory $miner_pid $mem_log &
    local monitor_pid=$!
    
    # Wait for test completion
    sleep $duration
    
    # Stop monitoring and mining
    kill $monitor_pid 2>/dev/null || true
    kill $miner_pid 2>/dev/null || true
    
    # Calculate average memory usage
    local avg_mem=$(awk -F',' 'NR>1 {sum+=$2; count++} END {print sum/count}' $mem_log)
    echo "$test_name average memory usage: ${avg_mem}KB"
    
    # Cleanup
    rm -f $mem_log
}

# Run comparison tests
echo "3. Running performance comparison tests..."
run_mining_test "./target/release/nockchain-original" "original"
run_mining_test "./target/release/nockchain-optimized" "optimized"

echo "=== Test completed ===" 