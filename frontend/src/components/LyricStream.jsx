import React, { useEffect, useState, useRef } from 'react';

const LyricStream = () => {
  const [lyrics, setLyrics] = useState('');
  const socketRef = useRef(null);

  useEffect(() => {
    const socket = new WebSocket('ws://localhost:8000/ws/generate/');
    socketRef.current = socket;

    socket.onopen = () => {
      console.log('WebSocket connected');
      // Send initial message (optional, based on backend expectations)
      socket.send(JSON.stringify({
        prompt: 'Write a song about a dragon and a girl',
        model: 'gpt-4'
      }));
    };

    socket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      const newText = data.text || '';
      setLyrics((prev) => prev + newText);
    };

    socket.onclose = () => {
      console.log('WebSocket disconnected');
    };

    socket.onerror = (err) => {
      console.error('WebSocket error:', err);
    };

    return () => {
      socket.close();
    };
  }, []);

  return (
    <div style={{ padding: '1rem', fontFamily: 'monospace' }}>
      <h2>🎶 Streaming Lyrics</h2>
      <pre style={{ whiteSpace: 'pre-wrap', wordWrap: 'break-word' }}>
        {lyrics || 'Waiting for lyrics...'}
      </pre>
    </div>
  );
};

export default LyricStream;
