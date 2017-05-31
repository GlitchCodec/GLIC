// final encoding

final static int ENCODING_RAW = 0;
final static int ENCODING_PACKED = 1;
final static int ENCODING_RLE = 2;

final static int ENCODINGNO = 3;

String encoding_name(int v) {
  switch(v) {
    case ENCODING_RAW: return "ENCODING RAW";
    case ENCODING_PACKED: return "ENCODING PACKED";
    case ENCODING_RLE: return "ENCODING RLE";
  }
  return null;
}
