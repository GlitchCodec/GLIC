static final int PRED_SAD = -1;
static final int PRED_BSAD = -2;
static final int PRED_RANDOM = -3;

static final int PRED_NONE = 0;
static final int PRED_CORNER = 1;
static final int PRED_H = 2;
static final int PRED_V = 3;
static final int PRED_DC = 4;
static final int PRED_DCMEDIAN = 5;
static final int PRED_MEDIAN = 6;
static final int PRED_AVG = 7;
static final int PRED_TRUEMOTION = 8;
static final int PRED_PAETH = 9;
static final int PRED_LDIAG = 10;
static final int PRED_HV = 11;
static final int PRED_JPEGLS = 12;
static final int PRED_DIFF = 13;
static final int PRED_REF = 14;
static final int PRED_ANGLE = 15;

static final int MAX_PRED = 16;

int[][] predict(int prediction, Planes p, int pno, Segment s) {
  switch(prediction) {
  case PRED_CORNER: 
    return pred_gen(p, pno, s, 0);
  case PRED_H: 
    return pred_gen(p, pno, s, 1);
  case PRED_V: 
    return pred_gen(p, pno, s, 2);
  case PRED_DC: 
    return pred_dc(p, pno, s);
  case PRED_DCMEDIAN: 
    return pred_dcmedian(p, pno, s);
  case PRED_MEDIAN: 
    return pred_median(p, pno, s);
  case PRED_AVG: 
    return pred_avg(p, pno, s);
  case PRED_TRUEMOTION: 
    return pred_truemotion(p, pno, s);
  case PRED_PAETH: 
    return pred_paeth(p, pno, s);
  case PRED_LDIAG: 
    return pred_ldiag(p, pno, s);
  case PRED_HV: 
    return pred_hv(p, pno, s);
  case PRED_JPEGLS: 
    return pred_jpegls(p, pno, s);
  case PRED_DIFF: 
    return pred_diff(p, pno, s);
  case PRED_REF: 
    return pred_ref(p, pno, s);
  case PRED_ANGLE: 
    return pred_angle(p, pno, s);
  case PRED_RANDOM: 
    return predict((int)random(MAX_PRED), p, pno, s);
  case PRED_SAD: 
    return pred_sad(p, pno, s, true);
  case PRED_BSAD: 
    return pred_sad(p, pno, s, false);
  default: 
    return new int[s.size][s.size];
  }
}

String predict_name(int prediction) {
  switch(prediction) {
  case PRED_CORNER: 
    return "PRED_CORNER";
  case PRED_H: 
    return "PRED_H";
  case PRED_V: 
    return "PRED_V";
  case PRED_DC: 
    return "PRED_DC";
  case PRED_DCMEDIAN: 
    return "PRED_DCMEDIAN";
  case PRED_MEDIAN: 
    return "PRED_MEDIAN";
  case PRED_AVG: 
    return "PRED_AVG";
  case PRED_TRUEMOTION: 
    return "PRED_TRUEMOTION";
  case PRED_PAETH: 
    return "PRED_PAETH";
  case PRED_LDIAG: 
    return "PRED_LDIAG";
  case PRED_HV: 
    return "PRED_HV";
  case PRED_JPEGLS: 
    return "PRED_JPEGLS";
  case PRED_DIFF: 
    return "PRED_DIFF";
  case PRED_REF: 
    return "PRED_REF";
  case PRED_ANGLE: 
    return "PRED_ANGLE";
  case PRED_RANDOM: 
    return "PRED_RANDOM";
  case PRED_SAD: 
    return "PRED_SAD";
  case PRED_BSAD: 
    return "PRED_BSAD";
  default: 
    return "PRED_NONE";
  }
}

int getSAD(int[][] pred, Planes p, int pno, Segment s) {
  int sum = 0;
  for (int x=0; x<s.size; x++) {
    for (int y=0; y<s.size; y++) {
      sum+=abs(p.get(pno, s.x+x, s.y+y)-pred[x][y]);
    }
  }
  return sum;
}

int[] pred_sad_stats = new int[MAX_PRED];
int[][] pred_sad(Planes p, int pno, Segment s, boolean do_sad) {
  int[][] currres = null;
  int currsad = do_sad ? MAX_INT : MIN_INT;
  int currtype = -1;

  for (int i=0; i<MAX_PRED; i++) {
    int[][] res = predict(i, p, pno, s);
    int sad = getSAD(res, p, pno, s);
    if ( (do_sad && sad<currsad) || (!do_sad && sad>currsad) ) {
      currsad = sad;
      currtype = s.pred_type;
      currres = res;
    }
  }

  s.pred_type = currtype;
  pred_sad_stats[currtype]++;
  return currres;
}

int[][] pred_gen(Planes p, int pno, Segment s, int type) {
  int[][] res = new int[s.size][s.size];

  for (int x=0; x<s.size; x++) {
    for (int y=0; y<s.size; y++) {
      switch(type) {
      case 0: 
        res[x][y] = p.get(pno, s.x-1, s.y-1); 
        break;
      case 1: 
        res[x][y] = p.get(pno, s.x-1, s.y+y); 
        break;
      case 2: 
        res[x][y] = p.get(pno, s.x+x, s.y-1); 
        break;
      }
    }
  }

  switch(type) {
  case 0: 
    s.pred_type = PRED_CORNER; 
    break;
  case 1: 
    s.pred_type = PRED_H; 
    break;
  case 2: 
    s.pred_type = PRED_V; 
    break;
  }
  return res;
}

int getDC(Planes p, int pno, Segment s) {
  int v = 0;
  for (int i=0; i<s.size; i++) {
    v += p.get(pno, s.x-1, s.y+i);
    v += p.get(pno, s.x+i, s.y-1);
  }
  v += p.get(pno, s.x-1, s.y-1);
  v /= (s.size+s.size+1);
  return v;
}

int getMedian(int a, int b, int c) {
  return max(min(a, b), min(max(a, b), c));
}

int[][] pred_dc(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];
  int c = getDC(p, pno, s);

  for (int x=0; x<s.size; x++) {
    for (int y=0; y<s.size; y++) {
      res[x][y] = c;
    }
  } 

  s.pred_type = PRED_DC;
  return res;
}

int[][] pred_dcmedian(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];
  int c = getDC(p, pno, s);

  for (int x=0; x<s.size; x++) {
    int v1 = p.get(pno, s.x+x, s.y-1);
    for (int y=0; y<s.size; y++) {
      int v2 = p.get(pno, s.x-1, s.y+y);
      res[x][y] = getMedian(c, v1, v2);
    }
  } 

  s.pred_type = PRED_DCMEDIAN;
  return res;
}

int[][] pred_median(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];
  int c = p.get(pno, s.x-1, s.y-1);

  for (int x=0; x<s.size; x++) {
    int v1 = p.get(pno, s.x+x, s.y-1);
    for (int y=0; y<s.size; y++) {
      int v2 = p.get(pno, s.x-1, s.y+y);
      res[x][y] = getMedian(c, v1, v2);
    }
  } 

  s.pred_type = PRED_MEDIAN;
  return res;
}

int[][] pred_truemotion(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];
  int c = p.get(pno, s.x-1, s.y-1);

  for (int x=0; x<s.size; x++) {
    int v1 = p.get(pno, s.x+x, s.y-1);
    for (int y=0; y<s.size; y++) {
      int v2 = p.get(pno, s.x-1, s.y+y);
      res[x][y] = constrain(v1+v2-c, 0, 255);
    }
  } 

  s.pred_type = PRED_TRUEMOTION;
  return res;
}

int[][] pred_paeth(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];
  int c = p.get(pno, s.x-1, s.y-1);

  for (int x=0; x<s.size; x++) {
    int v1 = p.get(pno, s.x+x, s.y-1);
    for (int y=0; y<s.size; y++) {
      int v2 = p.get(pno, s.x-1, s.y+y);
      int pp = v1+v2-c;
      int pa = abs(pp-v2);
      int pb = abs(pp-v1);
      int pc = abs(pp-c);
      int v = ((pa<=pb) && (pa<=pc))?v2:(pb<=pc?v1:c);
      res[x][y] = constrain(v, 0, 255);
    }
  } 

  s.pred_type = PRED_PAETH;
  return res;
}

int[][] pred_avg(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];

  for (int x=0; x<s.size; x++) {
    int v1 = p.get(pno, s.x+x, s.y-1);
    for (int y=0; y<s.size; y++) {
      int v2 = p.get(pno, s.x-1, s.y+y);
      res[x][y] = (v1+v2)>>1;
    }
  } 

  s.pred_type = PRED_AVG;
  return res;
}

int[][] pred_ldiag(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];

  for (int x=0; x<s.size; x++) {
    for (int y=0; y<s.size; y++) {
      int ss = x+y;
      int xx = p.get(pno, s.x+(ss+1<s.size?ss+1:s.size-1), s.y-1);
      int yy = p.get(pno, s.x-1, s.y+(ss<s.size?ss:s.size-1));
      int c = ((x+1)*xx+(y+1)*yy)/(x+y+2);
      res[x][y] = c;
    }
  } 

  s.pred_type = PRED_LDIAG;
  return res;
}

int[][] pred_hv(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];

  for (int x=0; x<s.size; x++) {
    for (int y=0; y<s.size; y++) {
      int c;
      if (x>y) c = p.get(pno, s.x+x, s.y-1);
      else if (y>x) c = p.get(pno, s.x-1, s.y+y);
      else c = (p.get(pno, s.x+x, s.y-1) + p.get(pno, s.x-1, s.y+y)) >> 1;
      res[x][y] = c;
    }
  } 

  s.pred_type = PRED_HV;
  return res;
}

int[][] pred_jpegls(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];

  for (int x=0; x<s.size; x++) {
    int c = p.get(pno, s.x+x-1, s.y-1);
    int a = p.get(pno, s.x+x, s.y-1);
    for (int y=0; y<s.size; y++) {
      int b = p.get(pno, s.x-1, s.y+y); 
      int v;
      if (c>=max(a, b)) v = min(a, b);
      else if (c<=min(a, b)) v=max(a, b);
      else v = a+b-c;
      res[x][y] = v;
    }
  } 

  s.pred_type = PRED_JPEGLS;
  return res;
}

int[][] pred_diff(Planes p, int pno, Segment s) {
  int[][] res = new int[s.size][s.size];

  for (int x=0; x<s.size; x++) {
    int x1 = p.get(pno, s.x+x, s.y-1);
    int x2 = p.get(pno, s.x+x, s.y-2);
    for (int y=0; y<s.size; y++) {
      int y1 = p.get(pno, s.x-1, s.y+y);
      int y2 = p.get(pno, s.x-2, s.y+y);
      int v = constrain((y2+y2-y1+x2+x2-x1)>>1, 0, 255);
      res[x][y] = v;
    }
  } 

  s.pred_type = PRED_DIFF;
  return res;
}

int[][] findBestRef(Planes p, int pno, Segment s) {
  int currsad = MAX_INT;
  int[][] currres = null;
  for (int i=0; i<45; i++) {
    int[][] res = new int[s.size][s.size];
    int xx = (int)random(-s.size, s.x);
    int yy;
    if (xx<s.x-s.size) {
      yy = (int)random(-s.size, s.y);
    } else {
      yy = (int)random(-s.size, s.y-s.size);
    }
    for (int x=0; x<s.size; x++) {
      for (int y=0; y<s.size; y++) {
        res[x][y] = p.get(pno, xx+x, yy+y);
      }
    }
    int sad = getSAD(res, p, pno, s);
    if (sad<currsad) {
      currres = res;
      currsad = sad;
      s.refx = xx;
      s.refy = yy;
    }
  }
  return currres;
}

int[][] pred_ref(Planes p, int pno, Segment s) {
  s.pred_type = PRED_REF;
  if (s.refx == Short.MAX_VALUE || s.refy == Short.MAX_VALUE) {
    return findBestRef(p, pno, s);
  } else {
    int[][] res = new int[s.size][s.size];
    for (int x=0; x<s.size; x++) {
      for (int y=0; y<s.size; y++) {
        res[x][y] = p.get(pno, s.refx+x, s.refy+y);
      }
    }
    return res;
  }
}

PVector getAngleRef(int i, int x, int y, float a, int w) {
  float xx=-1;
  float yy=-1;
  switch(i%3) {
  case 0: 
    {
      float v = (w-y-1)+x*a;
      xx = (v-w)/a;
      yy = (w-1-a-v);
      break;
    }
  case 1: 
    {
      float v = (w-x-1)+y*a;
      yy = (v-w)/a;
      xx = (w-1-a-v);
      break;
    }
  case 2: 
    {
      float v = x+y*a;
      yy = -1.0;
      xx = v + a;
      break;
    }
  }

  if (xx>yy)
    return new PVector(round(xx), -1);
  else
    return new PVector(-1, round(yy));
}

int[][] findBestAngle(Planes p, int pno, Segment s) {
  float stepa = 1.0/min(16, s.size);
  int[][] currres = null;
  int currsad = MAX_INT;

  for (int i=0; i<3; i++) {
    for (float a=0; a<1.0; a+=stepa) {
      float aa = ((int)(a*0x8000))/(float)0x8000;
      int[][] res = new int[s.size][s.size];

      for (int x=0; x<s.size; x++) {
        for (int y=0; y<s.size; y++) {
          PVector angref = getAngleRef(i, x, y, aa, s.size);
          int xx = angref.x >= s.size ? s.size-1 : (int)angref.x;
          res[x][y] = p.get(pno, xx+s.x, (int)angref.y+s.y);
        }
      }

      int sad = getSAD(res, p, pno, s);
      if (sad<currsad) {
        currres = res;
        currsad = sad;
        s.angle = a;
        s.refa = i;
      }
    }
  }
  return currres;
}

int[][] pred_angle(Planes p, int pno, Segment s) {
  s.pred_type = PRED_ANGLE;
  if (s.angle<0 || s.refa<0) {
    return findBestAngle(p, pno, s);
  } else {
    int[][] res = new int[s.size][s.size];
    for (int x=0; x<s.size; x++) {
      for (int y=0; y<s.size; y++) {
        PVector angref = getAngleRef(s.refa, x, y, s.angle, s.size);
        int xx = angref.x >= s.size ? s.size-1 : (int)angref.x;
        res[x][y] = p.get(pno, xx+s.x, (int)angref.y+s.y);
      }
    }
    return res;
  }
}
