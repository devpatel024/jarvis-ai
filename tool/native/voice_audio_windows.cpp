// JARVIS Windows process-only audio adapter. WinMM is supplied by Windows.
// PCM capture stays on stdout; playback reads WAV from stdin; no audio files.
#include <windows.h>
#include <mmsystem.h>
#include <io.h>
#include <fcntl.h>
#include <cstdio>
#include <cstring>
#include <vector>
#include <cstdint>

static bool read_exact(void *buffer, size_t length) {
  return fread(buffer, 1, length, stdin) == length;
}
static int capture() {
  WAVEFORMATEX format = {WAVE_FORMAT_PCM,1,16000,32000,2,16,0};
  HWAVEIN input = nullptr;
  if (waveInOpen(&input,WAVE_MAPPER,&format,0,0,CALLBACK_NULL) != MMSYSERR_NOERROR) return 3;
  char buffers[4][3200] = {}; WAVEHDR headers[4] = {};
  for (int i=0;i<4;++i) {
    headers[i].lpData=buffers[i];headers[i].dwBufferLength=sizeof(buffers[i]);
    if (waveInPrepareHeader(input,&headers[i],sizeof(WAVEHDR)) != MMSYSERR_NOERROR) return 4;
    waveInAddBuffer(input,&headers[i],sizeof(WAVEHDR));
  }
  waveInStart(input);
  for (;;) {
    for (int i=0;i<4;++i) if (headers[i].dwFlags & WHDR_DONE) {
      if (fwrite(headers[i].lpData,1,headers[i].dwBytesRecorded,stdout) != headers[i].dwBytesRecorded || fflush(stdout)) {
        waveInReset(input);waveInClose(input);return 0;
      }
      headers[i].dwBytesRecorded=0;waveInAddBuffer(input,&headers[i],sizeof(WAVEHDR));
    }
    Sleep(5);
  }
}
static int play() {
  char header[12];if (!read_exact(header,12) || memcmp(header,"RIFF",4) || memcmp(header+8,"WAVE",4)) return 5;
  WAVEFORMATEX format={}; bool haveFormat=false;
  for (;;) {
    char chunk[4];uint32_t length;
    if (!read_exact(chunk,4) || !read_exact(&length,4)) return 6;
    if (!memcmp(chunk,"data",4)) break;
    if (length > 65536) return 7;
    std::vector<char> payload(length + (length%2));
    if (!read_exact(payload.data(),payload.size())) return 8;
    if (!memcmp(chunk,"fmt ",4) && length>=16) { memcpy(&format,payload.data(),16);format.cbSize=0;haveFormat=true; }
  }
  if (!haveFormat || format.wFormatTag != WAVE_FORMAT_PCM || format.nChannels != 1 || format.wBitsPerSample != 16) return 9;
  HWAVEOUT output=nullptr;
  if (waveOutOpen(&output,WAVE_MAPPER,&format,0,0,CALLBACK_NULL) != MMSYSERR_NOERROR) return 10;
  char buffer[4096];size_t length;
  while ((length=fread(buffer,1,sizeof(buffer),stdin))>0) {
    WAVEHDR block={};block.lpData=buffer;block.dwBufferLength=(DWORD)length;
    waveOutPrepareHeader(output,&block,sizeof(block));
    if (waveOutWrite(output,&block,sizeof(block)) != MMSYSERR_NOERROR) { waveOutReset(output);waveOutClose(output);return 11; }
    while (!(block.dwFlags&WHDR_DONE)) Sleep(5);
    waveOutUnprepareHeader(output,&block,sizeof(block));
  }
  waveOutClose(output);return 0;
}
int main(int argc,char**argv) {
  _setmode(_fileno(stdin),_O_BINARY);_setmode(_fileno(stdout),_O_BINARY);
  if(argc!=2)return 2;
  if(!strcmp(argv[1],"capture"))return capture();
  if(!strcmp(argv[1],"play"))return play();
  return 2;
}
