enum ReplyLanguage { matchInput, english, gujarati }

class LlmSettings {
  const LlmSettings({
    this.model = 'llama3.2:1b',
    this.contextLength = 2048,
    this.language = ReplyLanguage.matchInput,
    this.keepAliveSeconds = 30,
  });
  final String model;
  final int contextLength, keepAliveSeconds;
  final ReplyLanguage language;
  bool get demo => model == 'Mock demo';
  String systemPromptFor(String input) {
    final chosen = language == ReplyLanguage.matchInput
        ? RegExp(r'[\u0a80-\u0aff]').hasMatch(input)
              ? ReplyLanguage.gujarati
              : ReplyLanguage.english
        : language;
    return LlmSettings(language: chosen).systemPrompt;
  }

  String get systemPrompt =>
      'You are JARVIS, a helpful local assistant. Be concise and honest when unsure. '
      '${switch (language) {
        ReplyLanguage.matchInput => 'Reply in the language of the latest user message: English or Gujarati.',
        ReplyLanguage.english => 'Reply in English.',
        ReplyLanguage.gujarati => 'Reply in Gujarati using Gujarati script, never Hindi or Devanagari unless the user explicitly requests it.',
      }} '
      'Do not pretend to execute tools or access live information.';
}
