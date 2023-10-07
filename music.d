import std.logger;
import std.stdio;
import std.math;

/// http://soundfile.sapp.org/doc/WaveFormat/
align(1)
struct RIFF {
  char[4] chunkId = "RIFF";
  uint chunkSize;
  char[4] format = "WAVE";
  char[4] subChunk1Id = "fmt ";
  uint subChunk1Size = 16;
  ushort audioFormat = 1; // 1:PCM, 3:float
  ushort numChannels;
  uint sampleRate;
  uint byteRate;
  ushort blockAlign;
  ushort bitsPerSample;
  char[4] subChunk2Id = "data";
  uint subChunk2Size;
}

void writeWav(T = short)(float[][] wav, int sampleRate, string outputPath) {
  auto numChannels = wav.length;
  auto numSamples = wav[0].length;
  RIFF header;
  header.numChannels = cast(ushort) numChannels;
  header.sampleRate = sampleRate;
  header.byteRate = cast(uint)(sampleRate * numChannels * T.sizeof);
  header.blockAlign = cast(ushort)(numChannels * T.sizeof);
  header.bitsPerSample = cast(ushort) T.sizeof * 8;
  header.subChunk2Size = cast(uint)(numSamples * header.numChannels * T.sizeof);
  header.chunkSize = header.subChunk2Size + cast(uint)(RIFF.sizeof - 8);
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

void main(string[] args) {
  int sampleRate = 44_100;
  float[][] wav; //  = new float[][](2, sampleRate * 3);
  wav.length = 2;
  foreach (ref w; wav) {
    w.length = sampleRate * 10;
  }
  info("#channels: ", wav.length);
  info("#frames: ", wav[0].length);
  foreach (t; 0 .. wav[0].length) {
    wav[0][t] = 0;
    wav[1][t] = 0;
    if ((cast(float) t / sampleRate % 0.5) < 0.1)
      continue;
    foreach (i; 1 .. 8) {
      wav[0][t] += 0.5 / i * sin(2.0 * PI * (44 + t * 0.01) * i * t / sampleRate);
      wav[1][t] += 0.5 * sin(2.0 * PI * 66 * i * t / sampleRate);
    }
    // wav[1][t] = wav[0][t];
    trace("time: ", t, " wav:", wav[0][t]);
  }
  writeWav(wav, sampleRate, args.length > 1 ? args[1] : "/dev/stdout");
}
