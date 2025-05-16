from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/generate/$', consumers.LyricConsumer.as_asgi()),
]
