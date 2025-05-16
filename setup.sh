#!/bin/bash

mkdir -p llm-lyrics-generator/backend/backend llm-lyrics-generator/backend/lyrics
mkdir -p llm-lyrics-generator/frontend/src/components

# Backend: requirements.txt
cat > llm-lyrics-generator/backend/requirements.txt <<EOF
Django>=4.2
channels
daphne
python-dotenv
litellm
EOF

# Backend: .env.example
cat > llm-lyrics-generator/backend/.env.example <<EOF
OPENAI_API_KEY=your-key
ANTHROPIC_API_KEY=your-key
GOOGLE_API_KEY=your-key
EOF

# Backend: manage.py
cat > llm-lyrics-generator/backend/manage.py <<'EOF'
#!/usr/bin/env python
import os
import sys

def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django."
        ) from exc
    execute_from_command_line(sys.argv)

if __name__ == '__main__':
    main()
EOF

# Backend: backend/__init__.py (empty)
touch llm-lyrics-generator/backend/backend/__init__.py

# Backend: backend/asgi.py
cat > llm-lyrics-generator/backend/backend/asgi.py <<'EOF'
import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from lyrics.routing import websocket_urlpatterns

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

application = ProtocolTypeRouter({
    'http': get_asgi_application(),
    'websocket': URLRouter(websocket_urlpatterns),
})
EOF

# Backend: backend/settings.py (minimal, only essentials)
cat > llm-lyrics-generator/backend/backend/settings.py <<'EOF'
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'your-secret-key'

DEBUG = True

ALLOWED_HOSTS = []

INSTALLED_APPS = [
    'django.contrib.staticfiles',
    'channels',
    'lyrics',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.common.CommonMiddleware',
]

ROOT_URLCONF = 'backend.urls'

TEMPLATES = []

WSGI_APPLICATION = 'backend.wsgi.application'
ASGI_APPLICATION = 'backend.asgi.application'

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels.layers.InMemoryChannelLayer',
    }
}

STATIC_URL = '/static/'

OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY')
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
EOF

# Backend: backend/urls.py
cat > llm-lyrics-generator/backend/backend/urls.py <<'EOF'
from django.urls import path

urlpatterns = []
EOF

# Backend: backend/wsgi.py
cat > llm-lyrics-generator/backend/backend/wsgi.py <<'EOF'
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

application = get_wsgi_application()
EOF

# Backend: lyrics/__init__.py
touch llm-lyrics-generator/backend/lyrics/__init__.py

# Backend: lyrics/routing.py
cat > llm-lyrics-generator/backend/lyrics/routing.py <<'EOF'
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/generate/$', consumers.LyricConsumer.as_asgi()),
]
EOF

# Backend: lyrics/consumers.py
cat > llm-lyrics-generator/backend/lyrics/consumers.py <<'EOF'
from channels.generic.websocket import AsyncWebsocketConsumer
import json
import litellm

class LyricConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.accept()

    async def receive(self, text_data):
        data = json.loads(text_data)
        prompt = data.get("prompt", "")
        model = data.get("model", "openai/gpt-4")

        async for chunk in litellm.acompletion(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            stream=True
        ):
            content = chunk.get("choices", [{}])[0].get("delta", {}).get("content", "")
            if content:
                await self.send(text_data=json.dumps({"text": content}))

        await self.send(text_data=json.dumps({"done": True}))
EOF

# Backend: lyrics/views.py (empty placeholder)
cat > llm-lyrics-generator/backend/lyrics/views.py <<'EOF'
# Placeholder for any REST views if needed
EOF

# Backend: lyrics/urls.py
cat > llm-lyrics-generator/backend/lyrics/urls.py <<'EOF'
from django.urls import path

urlpatterns = []
EOF

# Frontend: package.json
cat > llm-lyrics-generator/frontend/package.json <<'EOF'
{
  "name": "frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite"
  },
  "dependencies": {
    "react": "^18",
    "react-dom": "^18"
  },
  "devDependencies": {
    "vite": "^4",
    "@vitejs/plugin-react": "^3"
  }
}
EOF

# Frontend: vite.config.js
cat > llm-lyrics-generator/frontend/vite.config.js <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/ws': 'ws://localhost:8000',
    },
  },
})
EOF

# Frontend: index.html
cat > llm-lyrics-generator/frontend/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>LLM Lyrics Generator</title>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
EOF

# Frontend: src/main.jsx
cat > llm-lyrics-generator/frontend/src/main.jsx <<'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import LyricStream from "./components/LyricStream";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <LyricStream />
  </React.StrictMode>
);
EOF

# Frontend: src/components/LyricStream.jsx
cat > llm-lyrics-generator/frontend/src/components/LyricStream.jsx <<'EOF'
import { useState, useRef } from "react";

export default function LyricStream() {
  const [lyrics, setLyrics] = useState("");
  const ws = useRef(null);

  const startStreaming = () => {
    setLyrics("");
    ws.current = new WebSocket("ws://localhost:8000/ws/generate/");

    ws.current.onopen = () => {
      ws.current.send(
        JSON.stringify({
          prompt: "Write a verse about fire and dreams",
          model: "openai/gpt-4"
        })
      );
    };

    ws.current.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.text) {
        setLyrics((prev) => prev + data.text);
      }
      if (data.done) {
        ws.current.close();
      }
    };

    ws.current.onerror = (error) => {
      console.error("WebSocket error", error);
    };
  };

  return (
    <div style={{padding:"1rem"}}>
      <h2>Lyrics Generator</h2>
      <button onClick={startStreaming}>Generate Lyrics</button>
      <pre style={{whiteSpace:"pre-wrap", marginTop:"1rem"}}>{lyrics}</pre>
    </div>
  );
}
EOF

# Root README.md
cat > llm-lyrics-generator/README.md <<'EOF'
# LLM Lyrics Generator 🎤

A full-stack web app for generating song lyrics using LLMs like OpenAI, Claude, Gemini, and Ollama.

## Features

- Django backend with WebSocket streaming via Channels
- LiteLLM to abstract multiple LLM providers
- React frontend (Vite) to stream text in real time
- Support for OpenAI, Claude, Gemini, and local Ollama models

## Backend Setup (Django)

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # add your API keys
python manage.py migrate
python manage.py runserver
