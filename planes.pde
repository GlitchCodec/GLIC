final static float LOG2 = log(2.0);

final static int CLAMP_NONE = 0;
final static int CLAMP_MOD256 = 1;

int clamp_in(int method, int x) {
  switch(method) {
  case CLAMP_MOD256:
    return x<0?x+256:x>255?x-256:x;
  default: 
    return x;
  }
}

int clamp_out(int method, int x) {
  switch(method) {
  case CLAMP_MOD256: 
    return x<0?x+256:x>255?x-256:x;
  default: 
    return constrain(x, 0, 255);
  }
}

int clamp(int method, int x) {
  switch(method) {
  case CLAMP_MOD256:
    return constrain(x, 0, 255);
  default:
    return constrain(x, -255, 255);
  }
}

class RefColor {
  int[] c;
  public RefColor() {
    c = new int[] {
      128, 128, 128, 255
    };
  }

  public RefColor(int r, int g, int b) {
    this(color(r, g, b));
  }

  public RefColor(int r, int g, int b, int cs) {
    this(color(r, g, b), cs);
  }

  public RefColor(color cc) {
    c = new int[4];
    c[2] = cc & 0xff;
    c[1] = (cc >> 8) & 0xff;
    c[0] = (cc >> 16) & 0xff;
    c[3] = (cc >> 24) & 0xff;
  }

  public RefColor(color cc, int cs) {
    this(toColorspace(cc, cs));
  }
}

class Planes {
  int ww, hh;
  int w, h, cs;
  int[][][] channels;
  RefColor ref;

  public Planes(int[] pxls, int w, int h, int cs, RefColor ref) {
    this(w, h, cs, ref);
    extractPlanes(pxls);
  }

  public Planes(int w, int h, int cs) {
    this(w, h, cs, new RefColor(ccfg.color_outside, cs));
  }

  public Planes(int w, int h, int cs, RefColor ref) {
    this.w = w;
    this.h = h;
    this.cs = cs;
    ww = 1<<(int)ceil(log(w)/LOG2);
    hh = 1<<(int)ceil(log(h)/LOG2);
    //channels = new int[4][w][h];
    channels = new int[3][w][h];
    for (int x=0; x<w; x++) {
      for (int y=0; y<h; y++) {
        channels[0][x][y] = ref.c[0];
        channels[1][x][y] = ref.c[1];
        channels[2][x][y] = ref.c[2];
  //      channels[3][x][y] = ref.c[3];
      }
    }
    this.ref = ref;
  }

  public Planes(int[] pxls, int w, int h, int cs) {
    this(pxls, w, h, cs, new RefColor(ccfg.color_outside, cs));
  }

  public Planes clone() {
    return new Planes(w,h,cs,ref);
  }

  private void extractPlanes(int[] pxls) {
    for (int x=0; x<w; x++) {
      for (int y=0; y<h; y++) {
        color c = toColorspace(pxls[y*w+x], cs);
        channels[2][x][y] = c & 0xff;
        channels[1][x][y] = (c >> 8) & 0xff;
        channels[0][x][y] = (c >> 16) & 0xff;
    //    channels[3][x][y] = (c >> 24) & 0xff;
      }
    }
  }

  public int[] toPixels() {
    int[] pxls = new int[w*h];
    for (int x=0; x<w; x++) {
      for (int y=0; y<h; y++) {
        int off = y*w+x;
        pxls[off] = fromColorspace(
        (channels[2][x][y] ) |
          ((channels[1][x][y] ) << 8) |
          ((channels[0][x][y] ) << 16) |
          (img.pixels[off]&0xff000000)
        //  ((channels[3][x][y] ) << 24)
          , cs);
      }
    }
    return pxls;
  }

  public PImage toImage() {
    PImage i = createImage(w, h, ARGB);
    i.loadPixels();
    i.pixels = toPixels();
    i.updatePixels();
    return i;
  }

  public int get(int pno, int x, int y) {
    if (x<0 || x>=w || y<0 || y>=h) {
      return ref.c[pno];
    } else {
      return channels[pno][x][y];
    }
  }

  void set(int pno, int x, int y, int val) {
    if (x>=0 && x<w && y>=0 && y<h) {
      channels[pno][x][y] = val;
    }
  }

  double[][] get(int pno, Segment s) {
    double[][] res = new double[s.size][s.size];
    for (int x=0; x<s.size; x++) {
      for (int y=0; y<s.size; y++) {
        res[x][y] = get(pno, x+s.x, y+s.y)/255.0;
      }
    }
    return res;
  }

  void set(int pno, Segment s, double[][] values, int method) {
    for (int x=0; x<s.size; x++) {
      for (int y=0; y<s.size; y++) {
  //     set(pno, x+s.x, y+s.y, clamp(method,round((float)values[x][y])));
       set(pno, x+s.x, y+s.y, clamp(method,round((float)(values[x][y]*255.0))));
      }
    }
  }

  void subtract(int pno, Segment s, int[][] values, int clamp_method) {
    for (int x=0; x<s.size; x++) {
      for (int y=0; y<s.size; y++) {
        int v = get(pno, x+s.x, y+s.y) - values[x][y];
        set(pno, x+s.x, y+s.y, clamp_in(clamp_method, v));
      }
    }
  }

  void add(int pno, Segment s, int[][] values, int clamp_method) {
    for (int x=0; x<s.size; x++) {
      for (int y=0; y<s.size; y++) {
        int v = get(pno, x+s.x, y+s.y) + values[x][y];
        set(pno, x+s.x, y+s.y, clamp_out(clamp_method, v));
      }
    }
  }
}
