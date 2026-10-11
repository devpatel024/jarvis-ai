/* JARVIS process adapter. Vosk Apache-2.0; not an in-app native binding. */
#include <stdio.h>
#include <stdlib.h>
#include "vosk_api.h"
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif
int main(int argc, char **argv) {
  if (argc != 2) return 2;
#ifdef _WIN32
  _setmode(_fileno(stdin), _O_BINARY);
#endif
  vosk_set_log_level(-1);
  VoskModel *model = vosk_model_new(argv[1]);
  if (!model) return 3;
  VoskRecognizer *recognizer = vosk_recognizer_new(model, 16000.0f);
  if (!recognizer) { vosk_model_free(model); return 4; }
  char *pcm = malloc(640000);
  if (!pcm) return 5;
  size_t size = fread(pcm, 1, 640000, stdin);
  if (size == 640000 && fgetc(stdin) != EOF) return 6;
  vosk_recognizer_accept_waveform(recognizer, pcm, (int)size);
  puts(vosk_recognizer_final_result(recognizer));
  free(pcm); vosk_recognizer_free(recognizer); vosk_model_free(model);
  return 0;
}
