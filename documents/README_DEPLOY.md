# Qitanoid Deployment Modes

This project now has two primary deployment paths.

## 1. Simple Mode

Use this when you want the fastest install:

- one host
- one hub
- one dashboard
- local browser containers only
- no clusters or remote nodes

Main file:

- [client-deploy/docker-compose.yml](/Users/alexey/projects/qitaopsqa/client-deploy/docker-compose.yml)

Start:

```bash
cd /Users/alexey/projects/qitaopsqa/client-deploy
docker compose up -d
```

## 2. Distributed Mode

Use this when you want one central UI and multiple worker nodes.

Main files:

- central host: [deploy/compose/docker-compose.central.yml](/Users/alexey/projects/qitaopsqa/deploy/compose/docker-compose.central.yml)
- remote agent: [deploy/compose/docker-compose.agent.yml](/Users/alexey/projects/qitaopsqa/deploy/compose/docker-compose.agent.yml)
- agent env template: [deploy/compose/agent.env.example](/Users/alexey/projects/qitaopsqa/deploy/compose/agent.env.example)
- distributed smoke: [deploy/compose/smoke-nodes.sh](/Users/alexey/projects/qitaopsqa/deploy/compose/smoke-nodes.sh)

Guides:

- distributed workers: [README_AGENT.md](/Users/alexey/projects/qitaopsqa/README_AGENT.md)
- Helm / Kubernetes: [README_HELM.md](/Users/alexey/projects/qitaopsqa/README_HELM.md)

## Recommended reading order

If you are evaluating the product:

1. [README.md](/Users/alexey/projects/qitaopsqa/README.md)
2. [README_DEPLOY.md](/Users/alexey/projects/qitaopsqa/README_DEPLOY.md)
3. one of:
   - [client-deploy/docker-compose.yml](/Users/alexey/projects/qitaopsqa/client-deploy/docker-compose.yml)
   - [README_AGENT.md](/Users/alexey/projects/qitaopsqa/README_AGENT.md)
   - [README_HELM.md](/Users/alexey/projects/qitaopsqa/README_HELM.md)
