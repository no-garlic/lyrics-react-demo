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
