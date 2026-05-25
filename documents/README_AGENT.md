# Qitanoid Remote Agent

This guide covers running remote Docker workers as Qitanoid cluster agents.

## What the agent does

- runs on a separate worker host
- launches browser runtime containers locally on that worker
- registers itself in the Hub as a schedulable node
- sends heartbeats to the Hub
- allows the Hub to route Selenium, Playwright, and Appium launches to that worker

The same image is used for both roles:

- `qitaops/qitanoid-hub:1.0.3` for Hub mode
- `qitaops/qitanoid-hub:1.0.3` with `QITANOID_AGENT_MODE=true` for agent mode

## Requirements

- Linux host with Docker
- worker host reachable from the Hub on the agent port, default `7444`
- Hub reachable from the worker on `QITANOID_HUB_URL`
- Docker socket mount on the worker

## Important storage note

Remote agents are best paired with shared artifact/video storage.

- `S3-compatible video storage` is the recommended production option
- local filesystem video storage is node-local by nature
- if the Hub and worker do not share storage, runtime video files remain on the worker host

For production clusters, prefer the S3-backed video mode already supported by the Hub.

## Step 1: Create a node in the Hub UI

Open the `Nodes` screen in the dashboard:

- create a cluster if needed
- create a new node with mode `Remote agent`
- copy the generated bootstrap command or the `node_id` and `join_token`

## Step 2: Prepare the worker host

Copy the example env file:

```bash
cp ./deploy/compose/agent.env.example ./agent.env
```

Fill in:

- `QITANOID_HUB_URL`
- `QITANOID_NODE_ID`
- `QITANOID_NODE_TOKEN`
- `QITANOID_AGENT_PUBLIC_URL`

Use:

- `QITANOID_CONTAINER_HOST=127.0.0.1` on Linux
- `QITANOID_CONTAINER_HOST=host.docker.internal` only on Docker Desktop style setups where localhost port routing requires it

## Step 3: Start the agent

```bash
docker compose --env-file ./agent.env -f ./deploy/compose/docker-compose.agent.yml up -d
```

## Step 4: Verify registration

From the Hub machine:

```bash
curl http://YOUR_HUB_HOST:4444/api/nodes \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

The node should move to `online` after registration and heartbeat.

## Distributed smoke test

After the Hub and agent are both running:

```bash
cd /Users/alexey/projects/qitaopsqa
./deploy/compose/smoke-nodes.sh
```

What it verifies:

- creates a cluster
- registers or updates the remote node
- waits for the agent to become `online`
- launches Selenium on:
  - local node
  - explicit remote node
  - cluster routing
- launches Playwright on:
  - local node
  - explicit remote node
  - cluster routing
- verifies remote node capacity protection returns `503`

## How scheduling works

You can launch sessions in 3 modes:

- no node selected: Hub auto-selects a schedulable node
- cluster selected: Hub chooses a schedulable node inside that cluster
- explicit node selected: Hub routes directly to that node

Nodes in `draining` state are not chosen for new launches.

## Safe lifecycle

The Nodes UI supports:

- `Drain Node`
- `Enable Scheduling`
- `Delete Node`

Deletion is guarded:

- local Hub node cannot be deleted
- a node with active sessions cannot be deleted

## Example worker rollout

```bash
scp ./deploy/compose/docker-compose.agent.yml worker:/opt/qitanoid/
scp ./deploy/compose/agent.env.example worker:/opt/qitanoid/agent.env

ssh worker '
  cd /opt/qitanoid &&
  docker compose --env-file ./agent.env -f ./docker-compose.agent.yml up -d
'
```

## Troubleshooting

If the node stays `pending` or `offline`:

- confirm the worker can reach `QITANOID_HUB_URL`
- confirm the Hub can reach `QITANOID_AGENT_PUBLIC_URL`
- verify `QITANOID_NODE_ID` and `QITANOID_NODE_TOKEN`
- check worker logs:

```bash
docker compose --env-file ./agent.env -f ./deploy/compose/docker-compose.agent.yml logs -f
```

If launches fail after routing to the worker:

- confirm the worker host has free Docker capacity
- confirm browser images can be pulled on that worker
- confirm `QITANOID_CONTAINER_HOST` matches the worker runtime environment
