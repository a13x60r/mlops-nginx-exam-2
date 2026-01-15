## Exam Instructions

### MLOps Exam: Advanced Deployment with Nginx 🚀

#### Context

For this exam, you will implement a robust and secure MLOps architecture. The core of the project is to use **Nginx as an API Gateway** to serve a Machine Learning model through a **FastAPI** API. You must not only make the service functional, but also implement **production-grade features**: scalability, security, and modern deployment strategies.

#### Project Objectives

Your mission is to configure a complete containerized architecture that fulfills the following objectives:

1. **Reverse Proxy**  
   Nginx must act as the single entry point and route traffic to the appropriate API services.

2. **Load Balancing**  
   The main API (`api-v1`) must be deployed with multiple instances (**3 replicas**) to ensure high availability and load distribution.

3. **HTTPS Security**  
   All external communications must be encrypted via HTTPS. You will generate **self-signed certificates** for this purpose. Plain HTTP traffic must be automatically redirected to HTTPS.

4. **Access Control**  
   Access to the prediction endpoint (`/predict`) must be protected by **basic authentication** (username/password).

5. **Rate Limiting**  
   To protect the API against overload, the `/predict` endpoint must limit the number of requests (e.g., **10 requests per second per IP**).

6. **A/B Testing**  
   You will deploy two API versions:
   - `api-v1`: the standard version  
   - `api-v2`: a **debug** version that returns additional information  

   Nginx must route traffic to `api-v2` **only if** the request contains the HTTP header  
   `X-Experiment-Group: debug`.  
   Otherwise, traffic must be routed to `api-v1`.

7. **Monitoring (Bonus)**  
   Set up a monitoring stack using **Prometheus** and **Grafana** to collect and visualize Nginx metrics.

#### Target Architecture

Nginx acts as a central gateway, managing traffic between the different API versions and exposing metrics for monitoring.

```mermaid
graph TD
    subgraph "User"
        U[Client] -->|HTTPS Request| N
    end

    subgraph "Containerized Infrastructure (Docker)"
        N[Nginx Gateway] -->|Load Balancing| V1
        N -->|"A/B Test (Header)"| V2

        subgraph "API v1 (Scaled)"
            V1[Upstream: api-v1]
            V1_1[Replica 1]
            V1_2[Replica 2]
            V1_3[Replica 3]
            V1 --- V1_1
            V1 --- V1_2
            V1 --- V1_3
        end

        subgraph "API v2 (Debug)"
            V2[Upstream: api-v2]
        end

        subgraph "Monitoring Stack"
            N -->|/nginx_status| NE[Nginx Exporter]
            NE -->|Metrics| P[Prometheus]
            P -->|Data Source| G[Grafana]
            U_Grafana[Admin] -->|View Dashboards| G
        end
    end
