# n8n + Ollama Docker Setup

A Docker-based workflow automation system that combines **n8n** with a local **Ollama LLM server**, enabling you to build AI-powered workflows without relying on external APIs.

## What's Inside

This setup includes:

- **Ollama Server**: Local LLM server with the `qwen3:0.6b` model pre-loaded
- **n8n**: Powerful workflow automation platform for building AI agent workflows
- **Docker Compose**: Orchestrates both services with persistent storage

## Architecture

- **Ollama** runs on port `11435` (host) → `11434` (container)
- **n8n** runs on port `5678`
- Both services communicate via Docker's internal network
- Models and workflow data persist across container restarts

## Quick Setup Guide

### Prerequisites

- Docker and Docker Compose installed
- At least 2GB of free disk space (for the LLM model)

### Step-by-Step Setup

1. **Clone or download this repository**
   ```bash
   cd /path/to/agent-ai-n8n
   ```

2. **Configure environment variables**
   ```bash
   # The .env file is already configured with defaults
   # You can modify it if needed:
   # - OLLAMA_PORT: Default is 11434
   # - N8N_PORT: Default is 5678
   # - N8N_EMAIL: Your admin email
   # - N8N_PASSWORD: Your admin password
   ```

3. **Build and start the containers**
   ```bash
   docker compose up --build -d
   ```

   This will:
   - Build the Ollama container with the `qwen3:0.6b` model pre-loaded (~522 MB download)
   - Start both Ollama and n8n services
   - Take about 30-60 seconds on first run

4. **Verify containers are running**
   ```bash
   docker ps
   ```

   You should see both `ollama-server` and `n8n_local` with status "Up"

5. **Access n8n**
   - Open your browser and go to: **http://localhost:5678**
   - Login with your configured credentials:
     - Email: `example@email.com` (or your configured email)
     - Password: `pass` (or your configured password)

6. **Test Ollama (optional)**
   ```bash
   curl http://localhost:11435/api/generate -d '{"model":"qwen3:0.6b","prompt":"Hello","stream":false}'
   ```

## Using Ollama in n8n Workflows

### Setting Up Ollama Credentials

Before using Ollama in your workflows, you need to set up credentials:

1. In n8n, navigate to **Settings** → **Credentials**
2. Click **Add Credential** and search for "Ollama API"
3. Configure the credential:
   - **Name**: `Ollama account` (or any name you prefer)
   - **Base URL**: `http://ollama-server:11434`
   - Leave authentication fields empty (Ollama doesn't require auth by default)
4. Click **Save** and test the connection

**Important**: Always use the Docker service name `ollama-server:11434`, NOT `localhost:11435`

### Method 1: Using the Ollama Chat Model Node (Recommended)

The easiest way to use Ollama is with the **Ollama Chat Model** node from the LangChain integration:

1. Add the **Ollama Chat Model** node to your workflow
2. Select your Ollama credential
3. Choose the model: `qwen3:0.6b`
4. Connect it to an **AI Agent** or **Chain** node

This method provides better integration with n8n's AI agent features, including memory and tool support.

### Method 2: Using HTTP Request Node

For direct API calls, use the **HTTP Request** node:

```json
{
  "url": "http://ollama-server:11434/api/generate",
  "method": "POST",
  "body": {
    "model": "qwen3:0.6b",
    "prompt": "Your prompt here",
    "stream": false
  }
}
```

## Example: Building an AI Agent with Ollama

This repository includes a complete example workflow ([`workflows/test_workflow.json`](workflows/test_workflow.json)) that demonstrates how to build an AI agent powered by your local Ollama LLM.

### Workflow Components

The example workflow consists of 5 interconnected nodes:

1. **When chat message received** - Chat trigger that creates a webhook endpoint for receiving messages
2. **AI Agent** - Main orchestrator that coordinates the language model, memory, and tools
3. **Ollama Chat Model** - Connects to your local `qwen3:0.6b` model via the Ollama API credential
4. **Simple Memory** - Buffer window memory that maintains conversation context
5. **Execute Command** - Tool that allows the AI agent to execute shell commands

### How It Works

```
User Message → Chat Trigger → AI Agent → Response
                                  ↓
                    ┌─────────────┼─────────────┐
                    ↓             ↓             ↓
              Ollama Chat    Memory      Execute Command
               (qwen3)                        Tool
```

The AI agent:
- Receives messages through the chat trigger
- Uses the Ollama model to generate responses
- Maintains conversation history with memory
- Can execute shell commands when needed (via the Execute Command tool)

### Setting Up the Example Workflow

**Option 1: Import the Workflow**

1. In n8n, go to **Workflows** → **Add Workflow** → **Import from File**
2. Select `workflows/test_workflow.json`
3. Update the Ollama credential (if needed)
4. Activate the workflow

**Option 2: Build It Manually**

1. Create a new workflow
2. Add the following nodes:
   - **Chat Trigger** (from LangChain category)
   - **AI Agent** (from LangChain category)
   - **Ollama Chat Model** (from LangChain category)
   - **Window Buffer Memory** (from LangChain category)
   - **Execute Command Tool** (optional - allows AI to run commands)

3. Configure the Ollama Chat Model:
   - Credential: Select your Ollama API credential
   - Model: `qwen3:0.6b`

4. Connect the nodes:
   - Chat Trigger → AI Agent (main connection)
   - Ollama Chat Model → AI Agent (AI Language Model connection)
   - Window Buffer Memory → AI Agent (AI Memory connection)
   - Execute Command Tool → AI Agent (AI Tool connection)

### Testing Your AI Agent

1. **Activate the workflow** in n8n
2. **Open the chat interface**: Click the chat icon in the workflow view
3. **Start a conversation**:
   - User: "Hello, what can you help me with?"
   - AI: *Responds using the local Ollama model*
   - User: "What's 25 * 4?"
   - AI: *Calculates and responds*

The AI agent can:
- Answer questions using the local LLM
- Remember previous messages in the conversation
- Execute shell commands if you enable the Execute Command tool (use with caution!)

### Example Interaction

```
You: Hello! Can you tell me what model you are?
AI: I'm Qwen3, a 0.6B parameter language model running locally via Ollama.

You: What's the capital of France?
AI: The capital of France is Paris.

You: What did I just ask you about?
AI: You asked me about the capital of France, and I told you it's Paris.
```

Notice how the AI remembers the previous question thanks to the Memory node!

## Common Commands

```bash
# Start containers
docker compose up -d

# Stop containers
docker compose down

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f ollama-server
docker compose logs -f n8n

# Rebuild and restart
docker compose up --build -d

# Check container status
docker compose ps
```

## Directory Structure

```
.
├── Dockerfile              # Ollama container configuration
├── docker-compose.yml      # Multi-container orchestration
├── .env                    # Environment variables (not in git)
├── .env.template          # Environment variables template
├── workflows/             # n8n workflow definitions
│   └── test_workflow.json  # Example AI agent workflow
├── tools/                 # Custom n8n tools (auto-created)
├── CLAUDE.md              # Development guidelines
└── README.md              # This file
```

## Persistent Data

The following data persists across container restarts:
- **Ollama models**: Stored in Docker volume `ollama_models`
- **n8n data**: Stored in Docker volume `n8n_data`
- **Workflows**: Mounted to `./workflows/` directory
- **Tools**: Mounted to `./tools/` directory

## Changing the LLM Model

To use a different Ollama model:

1. Edit `Dockerfile` and change the model name:
   ```dockerfile
   RUN ollama serve & \
       sleep 5 && \
       ollama pull llama2 && \
       pkill -f "ollama serve"
   ```

2. Rebuild the container:
   ```bash
   docker compose up --build -d
   ```

Available models: https://ollama.com/library

## Troubleshooting

### Port Already in Use

If you see "address already in use" error:
- Another Ollama instance may be running on port 11435
- Change `OLLAMA_PORT` in `.env` to a different port (e.g., 11436)
- Restart: `docker compose up -d`

### n8n Not Accessible

- Check if containers are running: `docker compose ps`
- Check logs: `docker compose logs n8n`
- Ensure port 5678 is not blocked by your firewall

### Ollama Model Not Found

- The model downloads during the Docker build process
- Check build logs: `docker compose build`
- Verify model is available: `curl http://localhost:11435/api/tags`

## License

This project is provided as-is for educational and development purposes.
