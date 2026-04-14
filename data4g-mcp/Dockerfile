FROM python:3.12-slim

# Non-root user so repo mounts don't get root-owned artefacts
RUN useradd --create-home --shell /bin/bash data4g

WORKDIR /opt/data4g
COPY pyproject.toml README.md ./
COPY data4g ./data4g

RUN pip install --no-cache-dir .

USER data4g
WORKDIR /workspace

# stdio transport — agents spawn this container and speak MCP over pipes
ENTRYPOINT ["data4g-mcp"]
