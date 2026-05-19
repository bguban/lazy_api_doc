# Exchange Architecture

## Overview

Clients' orders enter the system through **Gateways (GWs)** and are forwarded to the **Matching Engine (ME)**. The ME is
responsible for matching and executing orders. **Liquidity Handlers** supply external price feeds to the ME and
can also be used to execute orders on external venues via **Exchange GWs**. A **Message Recorder (MR)** captures all
messages produced by the ME for persistence and State Machine Replication (SMR). A **Treasury Rebalancing Service**
manages the flow of funds between the internal exchange and external venues.

## Gateways (GWs)

### Traffic Mapping and Sharding

To ensure strict ordering, all traffic from a single account must be routed through a single GW instance. GWs are
sharded by Account ID, similar to a Redis cluster. If a client attempts to connect to the wrong GW, the request is
rejected with a redirect to the correct address.

### Sequencing and Deduplication

The GW is responsible for two critical data integrity tasks:

1. **Deduplication:** Clients must provide a unique **Client Transaction ID** for every command. The GW maintains a
   window of recently processed IDs to reject duplicate requests caused by network retries.
2. **Account-Level Sequencing:** The GW assigns a strictly increasing sequential number to every write command for a
   given account. This ensures that if a client sends a `Buy` followed by a `Cancel`, they are processed by the ME in
   that exact order, even if they arrive at the ME's network interface out of sequence.

### Throttling and Validation

GWs handle initial request validation and rate-limiting (throttling) to protect the core exchange from bursts or
malicious traffic.

## Trading Models

The exchange supports two primary models, with the complexity of risk management scaling accordingly.

### Spot Model (Recommended for Initial Phase)

Account balances are validated and "locked" before an order reaches the ME.

- **Workflow:** The GW (or a dedicated Account Shard) verifies sufficient available funds and moves them from
  `Available` to `Reserved`.
- **Settlement:** When the ME broadcasts a `Fill`, the GW settles the trade permanently. If the ME broadcasts a `Cancel`
  or `Expire`, the funds are moved from `Reserved` back to `Available`.
- **Benefits:** Simple, atomic settlement with zero risk of "Bad Debt."

### Margin / Futures Model

Users trade with leverage using collateral. This introduces cross-shard dependencies.

- **Risk Engine:** A dedicated Risk Engine sharded by Account ID monitors real-time prices for all instruments in a
  user's portfolio.
- **Liquidation:** If a user's "Maintenance Margin" falls below the required threshold, the Risk Engine must
  automatically:
    1. Cancel all open orders across all instrument shards.
    2. Submit market orders to liquidate positions.
- **Latency Trade-off:** Performing these checks at the GW adds latency. "Optimistic" execution (checking risk after the
  match) is faster but requires the exchange to have a robust insurance fund to cover potential bad debt.

## Communication Bus

The system uses a hybrid communication strategy:

- **UDP Multicast (Aeron):** Used for low-latency internal communication between GWs, MEs, and the Market Data feed.
  Aeron provides the speed of UDP with the reliability of TCP through built-in retransmission.
- **Stream Server (Apache Kafka):** Used for persistent, asynchronous tasks such as audit logging, reporting, and
  long-term storage in the Message Recorder.

## Matching Engine (ME)

### Total Ordering

The Primary ME acts as the sequencer for the entire exchange. Upon receiving a message, it assigns a global sequence
number and retransmits it over the communication bus. This allows Secondary MEs to replicate the state perfectly.

### Sharding by Instrument

To scale throughput, MEs are sharded by trading pair (e.g., BTC/USDT) or groups of pairs. This allows the exchange to
handle millions of orders per second by distributing the load across multiple CPU cores or machines.

### Determinism

To support State Machine Replication, the ME must be 100% deterministic:

- **Logical Time:** No use of system clocks. Time is derived from message timestamps or sequence numbers.
- **Fixed-Point Math:** Prices and amounts use `long` integers with fixed decimal multipliers to avoid floating-point
  rounding errors across different hardware.
- **No Hidden State:** All inputs (including random seeds) must be part of the message stream.

## Deployment and State Management

### Snapshotting and Copy-on-Write (CoW)

To ensure the ME can create a state snapshot without pausing execution, a **Copy-on-Write** mechanism is required. This
ensures the snapshot represents a consistent point-in-time state while the ME continues to process new orders.

1. **Secondary Node Snapshotting (Preferred):** In an SMR architecture, the **Primary ME** should focus exclusively on
   matching. A **Secondary ME** (or a dedicated "Snapshotter" node) performs the snapshot. It pauses briefly, captures
   the state, and then catches up by replaying messages from the bus. This offloads all disk I/O jitter from the
   critical path.
2. **OS-Level CoW (Fork):** On Linux, `fork()` can be used to create a child process that shares memory with the parent.
   The OS handles CoW automatically as the parent modifies memory. The child process then serializes the state to disk.
3. **Application-Level CoW:** Using immutable/persistent data structures (e.g., in Rust) allows for O(1) snapshots.
   However, this may introduce a performance overhead on every update (match/cancel).

### Machine-Agnostic Deployment

The system is designed to be hardware-independent, allowing MEs to be moved between physical servers without downtime.

1. **State Transfer:** Snapshots are serialized (using a portable format like FlatBuffers or `rkyv`) and stored on a
   network-accessible "State Server" (e.g., S3 or MinIO).
2. **Seeding a New Instance:** To deploy a new version (v2) of the ME:
    - Start ME v2 on a new physical machine.
    - Download the latest snapshot from the State Server.
    - Identify the **Last Sequence Number** in the snapshot.
    - Connect to the Communication Bus and replay all messages starting from `Last Sequence Number + 1`.
3. **Hot-Swap:** Once ME v2 has caught up to the "live" message stream, it can be promoted to Primary status, and the
   old ME v1 can be decommissioned.

## Liquidity Handlers and External Connectivity

The exchange maintains connectivity with the external world through a tiered system designed for modularity and
reliability.

### Liquidity Handlers
The Liquidity Handler is the internal orchestrator for all external market interactions. It performs:
1. **Aggregated Price Discovery:** Consolidating price feeds from multiple Exchange GWs into a single "Fair Price" for
   the ME.
2. **Smart Hedging:** Deciding which external venue should receive an offset order based on price, depth, and the
   exchange's current exposure.

### Exchange GWs
These are protocol-specific connectors (one per external exchange). They isolate the rest of the system from the
complexities of external APIs:
- **Normalization:** Converting external WebSocket/FIX messages into the exchange's internal canonical format.
- **Connection Management:** Handling API key authentication, rate-limiting, heartbeats, and automatic reconnection.

### Treasury Rebalancing Service
This service operates independently of the real-time matching loop. Its role is **Capital Management**:
- **Fund Movements:** Initiating on-chain withdrawals/deposits to move funds between the internal exchange wallets and
  external exchange accounts.
- **Rebalancing Logic:** Ensuring that the external Exchange GWs have enough "Dry Powder" (USDT/BTC) to execute hedging
  orders, while keeping the majority of assets in the exchange's cold storage.
