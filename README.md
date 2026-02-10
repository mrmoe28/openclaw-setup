# OpenClaw Setup

One-command installer for [OpenClaw](https://github.com/nicholasgriffintn/openclaw) with voice call support. Sets up a local AI voice assistant using Ollama + Twilio + ElevenLabs.

## What You Get

- **Ollama** running your local LLM (llama3.2)
- **OpenClaw** gateway with voice call plugin
- **Cloudflare Tunnel** for public webhook access (auto-detected, no manual URL copying)
- **Desktop shortcut** that launches everything in one click

## Prerequisites

- Windows 10/11
- [Ollama](https://ollama.com) installed with any model pulled
- A [Twilio](https://www.twilio.com) account (for phone calls)
- An [ElevenLabs](https://elevenlabs.io) API key (for text-to-speech)
- An [OpenAI](https://platform.openai.com) API key (for speech-to-text)

Node.js and cloudflared are installed automatically if missing.

## Install

```
git clone https://github.com/mrmoe28/openclaw-setup.git
cd openclaw-setup
install.bat
```

That's it. The installer will:

1. Check/install Node.js and cloudflared
2. Install OpenClaw globally via npm
3. Pull the llama3.2 model into Ollama
4. Create a config template at `%USERPROFILE%\.openclaw\openclaw.json`
5. Generate an app icon and desktop shortcut

## After Install

Edit `%USERPROFILE%\.openclaw\openclaw.json` and replace the placeholder values:

| Placeholder | Where to get it |
|---|---|
| `YOUR_TWILIO_ACCOUNT_SID` | [Twilio Console](https://console.twilio.com) |
| `YOUR_TWILIO_AUTH_TOKEN` | [Twilio Console](https://console.twilio.com) |
| `YOUR_TWILIO_PHONE_NUMBER` | Your Twilio phone number (e.g. `+18001234567`) |
| `YOUR_PHONE_NUMBER` | Your personal phone number (e.g. `+14045551234`) |
| `YOUR_ELEVENLABS_API_KEY` | [ElevenLabs Dashboard](https://elevenlabs.io) |
| `YOUR_OPENAI_API_KEY` | [OpenAI Platform](https://platform.openai.com/api-keys) |

## Usage

Double-click the **OpenClaw** shortcut on your desktop. It will:

1. Clean stale session locks
2. Start Ollama (if not already running)
3. Start a Cloudflare tunnel and **automatically update your config** with the new URL
4. Start the OpenClaw gateway with voice webhook
5. Wait for the gateway to come online, then **open the dashboard in your browser** with the auth token pre-filled

Three color-coded terminal windows will open so you can monitor each service.

## Architecture

```
Phone Call (Twilio)
    |
    v
Cloudflare Tunnel (public URL)
    |
    v
OpenClaw Voice Webhook (:3334)
    |
    +--> ElevenLabs (TTS)
    +--> OpenAI Whisper (STT)
    +--> Ollama llama3.2 (LLM response)
    |
    v
OpenClaw Gateway (:18789)
```

## License

MIT
