import jwave.transforms.*;
import jwave.transforms.wavelets.Wavelet;
import jwave.transforms.wavelets.WaveletBuilder;
import jwave.Transform;
import jwave.TransformBuilder;
import jwave.compressions.Compressor;
import jwave.compressions.CompressorMagnitude;
import jwave.compressions.CompressorPeaksAverage;
import jwave.exceptions.JWaveException;

final static int TRANSTYPE_RANDOM = -1;
final static int TRANSTYPE_FWT = 0;
final static int TRANSTYPE_WPT = 1;
//final static int TRANSTYPE_SWT = 2;

final static int TRANSTYPENO = 2;

WaveletTransform createTransform(int transtype, Wavelet wavelet) {
  switch (transtype) {
  case TRANSTYPE_FWT: 
    return new FastWaveletTransform(wavelet);
  case TRANSTYPE_WPT: 
    return new WaveletPacketTransform(wavelet);
//  case TRANSTYPE_SWT:
//    return new ShiftingWaveletTransform(wavelet);
  default: 
    return createTransform((int)random(TRANSTYPENO), wavelet);
  }
}

final static int WAVELETNO = 68;

final static int WAVELET_RANDOM = -1;
final static int WAVELET_NONE = 0;
final static int HAARORTHOGONAL = 1;
final static int BIORTHOGONAL11 = 2;
final static int BIORTHOGONAL13 = 3;
final static int BIORTHOGONAL15 = 4;
final static int BIORTHOGONAL22 = 5;
final static int BIORTHOGONAL24 = 6;
final static int BIORTHOGONAL26 = 7;
final static int BIORTHOGONAL28 = 8;
final static int BIORTHOGONAL31 = 9;
final static int BIORTHOGONAL33 = 10;
final static int BIORTHOGONAL35 = 11;
final static int BIORTHOGONAL37 = 12;
final static int BIORTHOGONAL39 = 13;
final static int BIORTHOGONAL44 = 14;
final static int BIORTHOGONAL55 = 15;
final static int BIORTHOGONAL68 = 16;
final static int COIFLET1 = 17;
final static int COIFLET2 = 18;
final static int COIFLET3 = 19;
final static int COIFLET4 = 20;
final static int COIFLET5 = 21;
final static int SYMLET2 = 22;
final static int SYMLET3 = 23;
final static int SYMLET4 = 24;
final static int SYMLET5 = 25;
final static int SYMLET6 = 26;
final static int SYMLET7 = 27;
final static int SYMLET8 = 28;
final static int SYMLET9 = 29;
final static int SYMLET10 = 30;
final static int SYMLET11 = 31;
final static int SYMLET12 = 32;
final static int SYMLET13 = 33;
final static int SYMLET14 = 34;
final static int SYMLET15 = 35;
final static int SYMLET16 = 36;
final static int SYMLET17 = 37;
final static int SYMLET18 = 38;
final static int SYMLET19 = 39;
final static int SYMLET20 = 40;
final static int LEGENDRE1 = 41;
final static int LEGENDRE2 = 42;
final static int LEGENDRE3 = 43;
final static int DAUBECHIES2 = 44;
final static int DAUBECHIES3 = 45;
final static int DAUBECHIES4 = 46;
final static int DAUBECHIES5 = 47;
final static int DAUBECHIES6 = 48;
final static int DAUBECHIES7 = 49;
final static int DAUBECHIES8 = 50;
final static int DAUBECHIES9 = 51;
final static int DAUBECHIES10 = 52;
final static int DAUBECHIES11 = 53;
final static int DAUBECHIES12 = 54;
final static int DAUBECHIES13 = 55;
final static int DAUBECHIES14 = 56;
final static int DAUBECHIES15 = 57;
final static int DAUBECHIES16 = 58;
final static int DAUBECHIES17 = 59;
final static int DAUBECHIES18 = 60;
final static int DAUBECHIES19 = 61;
final static int DAUBECHIES20 = 62;
final static int BATTLE23 = 63;
final static int CDF53 = 64;
final static int CDF97 = 65;
final static int DISCRETEMAYER = 66;
final static int HAAR = 67;

Wavelet createWavelet(int wavelettype) {
  switch(wavelettype) {
  case HAAR: 
    return new Haar1();
  case HAARORTHOGONAL: 
    return new Haar1Orthogonal();
  case DAUBECHIES2: 
    return new Daubechies2();
  case DAUBECHIES3: 
    return new Daubechies3();
  case DAUBECHIES4: 
    return new Daubechies4();
  case DAUBECHIES5: 
    return new Daubechies5();
  case DAUBECHIES6: 
    return new Daubechies6();
  case DAUBECHIES7: 
    return new Daubechies7();
  case DAUBECHIES8: 
    return new Daubechies8();
  case DAUBECHIES9: 
    return new Daubechies9();
  case DAUBECHIES10: 
    return new Daubechies10();
  case DAUBECHIES11: 
    return new Daubechies11();
  case DAUBECHIES12: 
    return new Daubechies12();
  case DAUBECHIES13: 
    return new Daubechies13();
  case DAUBECHIES14: 
    return new Daubechies14();
  case DAUBECHIES15: 
    return new Daubechies15();
  case DAUBECHIES16: 
    return new Daubechies16();
  case DAUBECHIES17: 
    return new Daubechies17();
  case DAUBECHIES18: 
    return new Daubechies18();
  case DAUBECHIES19: 
    return new Daubechies19();
  case DAUBECHIES20: 
    return new Daubechies20();
  case COIFLET1: 
    return new Coiflet1();
  case COIFLET2: 
    return new Coiflet2();
  case COIFLET3: 
    return new Coiflet3();
  case COIFLET4: 
    return new Coiflet4();
  case COIFLET5: 
    return new Coiflet5();
  case LEGENDRE1: 
    return new Legendre1();
  case LEGENDRE2: 
    return new Legendre2();
  case LEGENDRE3: 
    return new Legendre3();
  case SYMLET2: 
    return new Symlet2();
  case SYMLET3: 
    return new Symlet3();
  case SYMLET4: 
    return new Symlet4();
  case SYMLET5: 
    return new Symlet5();
  case SYMLET6: 
    return new Symlet6();
  case SYMLET7: 
    return new Symlet7();
  case SYMLET8: 
    return new Symlet8();
  case SYMLET9: 
    return new Symlet9();
  case SYMLET10: 
    return new Symlet10();
  case SYMLET11: 
    return new Symlet11();
  case SYMLET12: 
    return new Symlet12();
  case SYMLET13: 
    return new Symlet13();
  case SYMLET14: 
    return new Symlet14();
  case SYMLET15: 
    return new Symlet15();
  case SYMLET16: 
    return new Symlet16();
  case SYMLET17: 
    return new Symlet17();
  case SYMLET18: 
    return new Symlet18();
  case SYMLET19: 
    return new Symlet19();
  case SYMLET20: 
    return new Symlet20();
  case BIORTHOGONAL11: 
    return new BiOrthogonal11();
  case BIORTHOGONAL13: 
    return new BiOrthogonal13();
  case BIORTHOGONAL15: 
    return new BiOrthogonal15();
  case BIORTHOGONAL22: 
    return new BiOrthogonal22();
  case BIORTHOGONAL24: 
    return new BiOrthogonal24();
  case BIORTHOGONAL26: 
    return new BiOrthogonal26();
  case BIORTHOGONAL28: 
    return new BiOrthogonal28();
  case BIORTHOGONAL31: 
    return new BiOrthogonal31();
  case BIORTHOGONAL33: 
    return new BiOrthogonal33();
  case BIORTHOGONAL35: 
    return new BiOrthogonal35();
  case BIORTHOGONAL37: 
    return new BiOrthogonal37();
  case BIORTHOGONAL39: 
    return new BiOrthogonal39();
  case BIORTHOGONAL44: 
    return new BiOrthogonal44();
  case BIORTHOGONAL55: 
    return new BiOrthogonal55();
  case BIORTHOGONAL68: 
    return new BiOrthogonal68();
  case DISCRETEMAYER: 
    return new DiscreteMayer();
  case BATTLE23: 
    return new Battle23();
  case CDF53: 
    return new CDF53();
  case CDF97: 
    return new CDF97();
  default: 
    return createWavelet((int)random(1, WAVELETNO));
  }
}

Wavelet[] waveletTab = new Wavelet[WAVELETNO];
Wavelet getWavelet(int wavelettype) {
  if (wavelettype>=0 && wavelettype<WAVELETNO) {
    Wavelet w = waveletTab[wavelettype];
    if (w == null) {
      w = createWavelet(wavelettype);
      waveletTab[wavelettype] = w;
    }
    return w;
  } else {
    return createWavelet(-1);
  }
}
