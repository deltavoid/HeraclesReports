#!/bin/bash
# ops-per-worker is set to a very large value, so that TBENCH_MAXREQS controls how
# many ops are performed
NUM_WAREHOUSES=1
NUM_THREADS=1

QPS=2000
MAXREQS=40000
WARMUPREQS=20000

TBENCH_MAXREQS=${MAXREQS} TBENCH_WARMUPREQS=${WARMUPREQS} \
    perf stat -e cycles,instructions,cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    taskset 0x00000001 ./out-perf.masstree/benchmarks/dbtest_server_networked --verbose --bench \
    tpcc --num-threads ${NUM_THREADS} --scale-factor ${NUM_WAREHOUSES} \
    --retry-aborted-transactions --ops-per-worker 10000000 &

echo $! > server.pid

sleep 5 # Allow server to come up

    taskset 0x00000002 ./interfere/interfere &
echo $! > interfere1.pid

    taskset 0x00000004 ./interfere/interfere2 &
echo $! > interfere2.pid


TBENCH_QPS=${QPS} TBENCH_MINSLEEPNS=10000 \
    taskset 0x00000008 ./out-perf.masstree/benchmarks/dbtest_client_networked &

echo $! > client.pid

wait $(cat client.pid)

sleep 2

# Clean up
./kill_networked.sh
./kill_interfere.sh

python ../utilities/parselats.py lats.bin

