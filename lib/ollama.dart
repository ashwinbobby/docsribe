class OllamaConfig {
  // Set your current ngrok HTTPS forwarding URL here.
  // Example: https://abc123.ngrok-free.app
  static const String baseUrl = 'https://presartorial-unprovincially-selina.ngrok-free.dev';

  // Keep this in sync with your local Ollama model tag.
  // Example: qwen2.5-coder:7b
  static const String model = 'qwen2.5-coder:7b';

  // auto: try Ollama first, fallback to hosted
  // ollama: prefer Ollama first, fallback to hosted
  // hosted: use hosted model only
  static const String provider = 'auto';
}
