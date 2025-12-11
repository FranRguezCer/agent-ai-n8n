# Usa la imagen oficial de Ollama, que ya viene preconfigurada.
FROM ollama/ollama

# Expone el puerto por defecto de Ollama (11434).
EXPOSE 11434

# Start Ollama server in background, pull model, then stop the server
# This allows the model to be pre-loaded during the Docker build process
RUN ollama serve & \
    sleep 5 && \
    ollama pull qwen3:0.6b && \
    pkill -f "ollama serve"
