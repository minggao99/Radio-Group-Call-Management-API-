## README.md

# Motorola Software Engineer Interview Challenge: Radio Group Call Management API 

## Table of Contents
- [Feature Overview](#feature-overview)
  - [Basic Functionality](#basic-functionality)
  - [Bonus Challenges 1–6](#bonus-challenges-1–6)
- [Instructions to Run the Code](#instructions-to-run-the-code)
  - [Requirements](#requirements)
  - [Run Locally with Docker](#1-run-locally-with-docker)
  - [Run on Local Kubernetes Cluster](#2-run-on-local-kubernetes-cluster-bonus-challenge-6)
  - [Run via Docker Elixir Container](#3-run-via-docker-elixir-container)
  - [Basic Requirements Examples](#4-basic-requirements-examples)
  - [Floor Timeout Auto Release Examples (Bonus Challenge 1)](#5-floor-timeout-auto-release-examples-bonus-challenge-1)
  - [List Floor Holder (Bonus Challenge 2)](#6-list-floor-holder-bonus-challenge-2)
  - [Priority-Based Floor Control (Bonus Challenge 3)](#7-priority-based-floor-control-bonus-challenge-3)
  - [Audit Endpoint (Bonus Challenge 4)](#8-audit-endpoint-bonus-challenge-4)
- [CI Pipeline](#ci-pipeline-bonus-challenge-5)
- [Author](#author)

---
## Feature Overview
### Basic Functionality
- Implements a radio group call management system using Elixir.
- Each group runs as its own GenServer process, ensuring that only one user can hold the floor at a time.
- The API supports requesting, releasing, and querying floor ownership via REST endpoints.
- The API can run fully in Docker.

### Bonus Challenges 1-6
- Adds automatic floor release after 10 seconds of inactivity.
- Adds 4 priority levels (P1~P4), allowing higher-priority users to preempt lower-priority users who currently hold the floor.
- Adds endpoint to query who currently holds the floor and return both the user ID and priority level.
- Implements a global auditserver that records all floor events (granted, released, preempted, timeout).
- CI pipeline automatically installs dependencies, compiles, and runs tests on each push.
- Add the function of deploying the app to a local Kubernetes cluster (with Kind).

---

## Instructions to run the code
### Requirements
- Docker Desktop (Windows/Mac/Linux)

### (1) Run locally with Docker

```bash
docker build -t floor_control_app .
docker run --rm -p 8080:8080 floor_control_app

curl http://localhost:8080
# This would show "FloorControl API is running"

curl -X POST http://localhost:8080/groups/test/floor \
     -H "Content-Type: application/json" \
     -d '{"userId":"u1","priority":"3"}'

curl http://localhost:8080/groups/test/floor
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
Expected Output:
"FloorControl API is running"


### (3) Run via Docker Elixir container
```bash
docker run -it -v ${PWD}:/app -w /app elixir:1.15 bash
mix deps.get
mix run --no-halt
```

### (4) Basic Requirements Examples
```bash
curl -X POST http://localhost:8080/groups/team1/floor \
     -H "Content-Type: application/json" \
     -d '{"userId":"userA"}'
```

Expected Output:
{"status":"granted","holder":"userA"}

If conflict happens
```bash
curl -X POST http://localhost:8080/groups/team1/floor \
     -H "Content-Type: application/json" \
     -d '{"userId":"userB"}'
```

Expected Output:
{"status":"conflict","holder":"userA"}

### (5) Floor Timeout Auto Release Examples (Bonus Challenge 1)
```bash
curl -X POST http://localhost:8080/groups/timeout/floor \
     -H "Content-Type: application/json" \
     -d '{"userId":"userA"}'
```

After 10s
```bash
curl http://localhost:8080/groups/timeout/floor
```
Expected Output: 
{"holder":null}

### (6) List Floor Holder (Bonus Challenge 2)
```bash
curl http://localhost:8080/groups/priority/floor
```

Expected Output:
{"holder":"userB","priority":1}


### (7) Priority-Based Floor Control (Bonus Challenge 3)
```bash
curl -X POST http://localhost:8080/groups/priority/floor \
     -H "Content-Type: application/json" \
     -d '{"userId":"userA","priority":"3"}'

curl -X POST http://localhost:8080/groups/priority/floor \
     -H "Content-Type: application/json" \
     -d '{"userId":"userB","priority":"1"}'
```

Expected Output:
{"status":"preempted","holder":"userB","priority":1}

### (8) Audit Endpoint (Bonus Challenge 4)
```bash
curl http://localhost:8080/audit
```

Expected Output:
{
  "audit_log": [
    {"group":"priority","user":"userA","action":"granted","priority":3,"timestamp":"2025-10-12T09:31:44Z"},
    {"group":"priority","user":"userB","action":"preempted","priority":1,"timestamp":"2025-10-12T09:31:52Z"}
  ]
}


## CI Pipeline (Bonus Challenge 5)
### If you want to run tests locally:
```bash
mix test
```

### Alternatively
Every commit triggers:
```bash
mix deps.get
mix compile 
mix test 
```

## Author
Ming Gao

