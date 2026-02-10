$ocDir = Join-Path $env:USERPROFILE ".openclaw"
if (-not (Test-Path $ocDir)) { New-Item -ItemType Directory -Path $ocDir | Out-Null }

$config = @{
    meta = @{
        lastTouchedVersion = "2026.2.9"
        lastTouchedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    models = @{
        mode = "merge"
        providers = @{
            ollama = @{
                baseUrl = "http://127.0.0.1:11434/v1"
                apiKey = "ollama-local"
                api = "openai-completions"
                models = @(
                    @{
                        id = "llama3.2"
                        name = "Llama 3.2 3B"
                        reasoning = $false
                        input = @("text")
                        cost = @{ input = 0; output = 0; cacheRead = 0; cacheWrite = 0 }
                        contextWindow = 128000
                        maxTokens = 8192
                    }
                )
            }
        }
    }
    agents = @{
        defaults = @{
            model = @{
                primary = "ollama/llama3.2"
                fallbacks = @("ollama/llama3.2")
            }
            workspace = (Join-Path $env:USERPROFILE ".openclaw\workspace")
            compaction = @{ mode = "safeguard" }
            maxConcurrent = 4
            subagents = @{ maxConcurrent = 8 }
        }
    }
    messages = @{
        tts = @{
            auto = "off"
            provider = "elevenlabs"
            elevenlabs = @{
                apiKey = "YOUR_ELEVENLABS_API_KEY"
                modelId = "eleven_multilingual_v2"
                voiceSettings = @{
                    stability = 0.5
                    similarityBoost = 0.75
                    style = 0.0
                    useSpeakerBoost = $true
                    speed = 1.0
                }
            }
        }
    }
    gateway = @{
        port = 18789
        mode = "local"
        bind = "loopback"
        auth = @{
            mode = "token"
            token = [guid]::NewGuid().ToString("N")
        }
    }
    plugins = @{
        entries = @{
            "voice-call" = @{
                enabled = $true
                config = @{
                    provider = "twilio"
                    fromNumber = "YOUR_TWILIO_PHONE_NUMBER"
                    toNumber = "YOUR_PHONE_NUMBER"
                    twilio = @{
                        accountSid = "YOUR_TWILIO_ACCOUNT_SID"
                        authToken = "YOUR_TWILIO_AUTH_TOKEN"
                    }
                    tts = @{
                        provider = "elevenlabs"
                        elevenlabs = @{
                            apiKey = "YOUR_ELEVENLABS_API_KEY"
                            modelId = "eleven_multilingual_v2"
                        }
                    }
                    serve = @{
                        port = 3334
                        path = "/voice/webhook"
                    }
                    publicUrl = "https://WILL-BE-AUTO-DETECTED.trycloudflare.com/voice/webhook"
                    skipSignatureVerification = $true
                    responseModel = "ollama/llama3.2"
                    responseTimeoutMs = 60000
                    responseSystemPrompt = "You are a friendly voice assistant on a phone call. Reply with a brief 1-2 sentence spoken response. Do NOT use any tools. Just reply naturally to what the caller said."
                    maxConcurrentCalls = 3
                    outbound = @{ defaultMode = "conversation" }
                    streaming = @{
                        enabled = $true
                        streamPath = "/voice/stream"
                        openaiApiKey = "YOUR_OPENAI_API_KEY"
                    }
                }
            }
        }
    }
}

$json = $config | ConvertTo-Json -Depth 10
$configPath = Join-Path $ocDir "openclaw.json"
$json | Set-Content $configPath -Encoding UTF8
Write-Host "Config template created at: $configPath"
