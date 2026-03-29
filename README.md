# DocScribe

Flutter app for voice-to-prescription extraction.

## Use Local Ollama Through ngrok

This app now supports a local Ollama backend (for example `qwen2.5-coder:7b`) and safely falls back to the hosted model if Ollama is unavailable.

### 1. Start Ollama and pull model

```powershell
ollama serve
ollama pull qwen2.5-coder:7b
```

### 2. Expose Ollama with ngrok

Ollama runs on `11434` by default:

```powershell
ngrok http 11434
```

Copy the public HTTPS URL from ngrok, for example:
`https://abc123.ngrok-free.app`

### 3. Run Flutter with Ollama config

```powershell
flutter run --dart-define=DOCSCRIBE_LLM_PROVIDER=auto --dart-define=DOCSCRIBE_OLLAMA_BASE_URL=https://abc123.ngrok-free.app --dart-define=DOCSCRIBE_OLLAMA_MODEL=qwen2.5-coder:7b
```

## Backend Behavior

- `DOCSCRIBE_LLM_PROVIDER=auto`:
	- Use Ollama first if `DOCSCRIBE_OLLAMA_BASE_URL` is set.
	- Fall back to hosted model if Ollama fails.
- `DOCSCRIBE_LLM_PROVIDER=ollama`:
	- Prefer Ollama first.
	- Still falls back to hosted model to avoid breaking core functionality.
- `DOCSCRIBE_LLM_PROVIDER=hosted`:
	- Use only hosted model path.

Required Ollama define:

- `DOCSCRIBE_OLLAMA_BASE_URL`: your ngrok HTTPS URL.

Optional define:

- `DOCSCRIBE_OLLAMA_MODEL`: defaults to `qwen2.5-coder:7b`.
