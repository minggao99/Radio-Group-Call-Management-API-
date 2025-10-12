## README.md

# Motorola Software Engineer Interview Challenge: Radio Group Call Management API 

## 📑 Table of Contents
- [Feature Overview](#feature-overview)
  - [Basic Functionality](#basic-functionality)
  - [Bonus Challenges 1–6](#bonus-challenges-1–6)
- [Instructions to Run the Code](#instructions-to-run-the-code)
  - [Run Locally with Docker](#1-run-locally-with-docker)
  - [Run on Local Kubernetes Cluster](#2-run-on-local-kubernetes-cluster-bonus-challenge-6)
  - [Run via Docker Elixir Container](#3-run-via-docker-elixir-container)
- [CI Pipeline](#ci-pipeline)
- [Author](#author)

---
## Feature Overview
### Basic Functionality
· Implements a radio group call management system using Elixir.
· Each group runs as its own GenServer process, ensuring that only one user can hold the floor at a time.
· The API supports requesting, releasing, and querying floor ownership via REST endpoints.

### Bonus CHallenges 1-6
· Adds automatic floor release after 10 seconds of inactivity.
· Adds 4 priority levels (P1–P4), allowing higher-priority users to preempt lower-priority holders.
· Adds endpoint to query who currently holds the floor and return both the user ID and priority level.
· Implements a global AuditServer that records all floor events (granted, released, preempted, timeout).
· CI pipeline automatically installs dependencies, compiles, and runs tests on each push.
· Add the function of deploying the app to a local Kubernetes cluster (for example with Kind).

---

## Instructions to run the code
### (1) **Run Locally with Docker**

```bash
docker build -t floor_control_app .
docker run --rm -p 8080:8080 floor_control_app

curl http://localhost:8080
# "FloorControl API is running"

curl -X POST http://localhost:8080/groups/test/floor \
     -H "Content-Type: application/json" \
     -d '{"userId":"u1","priority":"3"}'

curl http://localhost:8080/groups/test/floor

[AUTO RELEASE] Group test — floor released due to timeout.

curl http://localhost:8080/audit

```

### (2) Run on Local Kubernetes Cluster (Bonus Challenge 6)
```bash
kind create cluster --name floor-control
docker build -t floor_control_app .
kind load docker-image floor_control_app --name floor-control

kubectl apply -f k8s-deployment.yml
kubectl apply -f k8s-service.yml

kubectl port-forward service/floor-control-service 8080:8080
curl http://localhost:8080
```

### (3) Run via Docker Elixir container
```bash
docker run -it -v ${PWD}:/app -w /app elixir:1.15 bash
mix deps.get
mix run --no-halt
```

## CI Pipeline
### If you want to run tests locally:
```bash
mix test
```

### Otherwise
Every commit triggers:
```bash
  mix deps.get
  mix compile --warnings-as-errors
  mix test 
```

## Author
Ming Gao

