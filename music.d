import std.stdio;
import std.math;

/// http://soundfile.sapp.org/doc/WaveFormat/
align(1) struct RIFF {
  char[4] chunkId = "RIFF";
  int chunkSize;
  char[4] format = "WAVE";
  char[4] subChunk1Id = "fmt ";
  int subChunk1Size = 16;
  short audioFormat = 1; // 1:PCM, 3:float
  short numChannels;
  int sampleRate;
  int byteRate;
  short blockAlign;
  short bitsPerSample;
  char[4] subChunk2Id = "data";
  int subChunk2Size;
}

void writeWav(T = short)(float[][] wav, int sampleRate, string outputPath) {
  auto numChannels = wav.length;
  auto numSamples = wav[0].length;
  RIFF header;
  header.numChannels = cast(short) numChannels;
  header.sampleRate = sampleRate;
  header.byteRate = cast(int)(sampleRate * numChannels * T.sizeof);
  header.blockAlign = cast(short)(numChannels * T.sizeof);
  header.bitsPerSample = cast(short) T.sizeof * 8;
  header.subChunk2Size = cast(int)(numSamples * header.numChannels * T.sizeof);
  header.chunkSize = 36 + header.subChunk2Size;
  FILE* fp = fopen(outputPath.ptr, "wb");
  scope (exit) {
    fclose(fp);
  }
  fwrite(&header, RIFF.sizeof, 1, fp);
  foreach (t; 0 .. numSamples) {
    foreach (ch; 0 .. numChannels) {
      T w = cast(T)(wav[ch][t] * (2 ^^ (header.bitsPerSample - 1) - 1));
      fwrite(&w, T.sizeof, 1, fp);
    }
  }
}

void main() {
  int sampleRate = 44100;
  float[][] wav = new float[][](sampleRate * 3, 2);
  foreach (t; 0 .. wav[0].length) {
    wav[0][t] = sin(2.0 * PI * 440 / sampleRate);
    wav[1][t] = wav[0][t];
  }
  writeWav(wav, sampleRate, "output.wav");
}
