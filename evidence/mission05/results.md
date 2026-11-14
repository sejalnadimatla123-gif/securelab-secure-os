
# Mission 5: Race Condition and Mutex

## Objective
Demonstrate a race condition using two threads and fix it using a mutex.

## Experiment 1: Without Mutex
- Threads: 2
- Increments per thread: 1,000,000
- Expected counter: 2,000,000
- Runs: 5
- Correct results: 2
- Incorrect results: 3

## Experiment 2: With Mutex
- Threads: 2
- Increments per thread: 1,000,000
- Expected counter: 2,000,000
- Runs: 5
- Correct results: 5

## Observation
Without synchronization, concurrent increments caused lost updates in 3 out of 5 runs. With mutex protection, all 5 runs produced the expected result.

## Security Relevance
Race conditions can allow concurrent operations to interfere with shared state, potentially causing incorrect access-control decisions or inconsistent security-sensitive data.

## Defense
Use mutex locks to protect critical sections that access shared mutable data.
