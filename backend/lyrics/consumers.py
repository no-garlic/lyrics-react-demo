# consumers.py

import json
from channels.generic.websocket import AsyncWebsocketConsumer
import litellm

class LyricsConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.accept()
        print("WebSocket connection accepted")

    async def disconnect(self, close_code):
        print("WebSocket disconnected")

    async def receive(self, text_data):
        data = json.loads(text_data)
        prompt = data.get("prompt", "Write me a song")
        model = data.get("model", "gpt-4")

        try:
            # Important: stream=True
            response = litellm.completion(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a creative lyrics assistant."},
                    {"role": "user", "content": prompt},
                ],
                stream=True,
            )

            # Stream each chunk over the WebSocket
            async for chunk in response:
                content = chunk.get("choices", [{}])[0].get("delta", {}).get("content", "")
                if content:
                    await self.send(text_data=json.dumps({"text": content}))
        except Exception as e:
            print(f"Error in streaming: {e}")
            await self.send(text_data=json.dumps({"error": str(e)}))
