class Segment {
  int x,y,size;
  
  // needed for prediction
  int pred_type = PRED_NONE;
  float angle = -1;
  int refa = -1;
  int refx = Short.MAX_VALUE; /// set to -1 if you want grid effect
  int refy = Short.MAX_VALUE; /// set to -1 if you want grid effect
  
  public String toString() {
    return "x="+x+", y="+y+ ", size=" + size;
  }
}

ArrayList<Segment> makeSegmentation(DefaultBitOutput segm_out, Planes p, int pno, int min_size, int max_size, float thr) throws IOException {
  ArrayList<Segment> s = new ArrayList<Segment>();
  
  segment(segm_out, s, p, pno, 0, 0, max(p.ww,p.hh), max(1,min_size), min(512,max_size), thr);
  
  return s;
}

void segment(DefaultBitOutput segm_out, ArrayList<Segment> s, Planes p, int pno, int x, int y, int size, int min_size, int max_size, float thr) throws IOException {
  if(x>=p.w || y>=p.h) return;
  float currStdDev = calcStdDev(p, pno, x, y, size);
  if(size>max_size || (size>min_size && currStdDev>thr)) {
    segm_out.writeBoolean(true);
    int mid = size/2;
    segment(segm_out,s,p,pno,x,y,mid,min_size,max_size,thr);
    segment(segm_out,s,p,pno,x+mid,y,mid,min_size,max_size,thr);
    segment(segm_out,s,p,pno,x,y+mid,mid,min_size,max_size,thr);
    segment(segm_out,s,p,pno,x+mid,y+mid,mid,min_size,max_size,thr);
  } else {
    segm_out.writeBoolean(false);
    Segment segm = new Segment();
    segm.x = x;
    segm.y = y;
    segm.size = size;
    s.add(segm);
  }
}

ArrayList<Segment> readSegmentation(DefaultBitInput segm_in, Planes p) {
  ArrayList<Segment> s = new ArrayList<Segment>();
  
  segment(segm_in, s, p, 0, 0, max(p.ww,p.hh));
  
  return s;
}

void segment(DefaultBitInput segm_in, ArrayList<Segment> s, Planes p, int x, int y, int size) {
  if(x>=p.w || y>=p.h) return;
  boolean decision;
  try { 
    decision = segm_in.readBoolean();
  } catch (Exception e) {
    decision = false;
  }
  if(decision && size > 2) {
    int mid = size/2;
    segment(segm_in,s,p,x,y,mid);
    segment(segm_in,s,p,x+mid,y,mid);
    segment(segm_in,s,p,x,y+mid,mid);
    segment(segm_in,s,p,x+mid,y+mid,mid);
  } else {
    Segment segm = new Segment();
    segm.x = x;
    segm.y = y;
    segm.size = size;
    s.add(segm);
  }
}

float calcStdDev(Planes planes, int pno, int x, int y, int size) {
  int limit = (int)(max(0.1*sq(size),4));
  
  float A = 0;
  float Q = 0;
  for(int k=1;k<=limit;k++) {
    int posx = (int)random(size);
    int posy = (int)random(size);
    
    int xk = planes.get(pno,x+posx,y+posy);
    
    float oldA = A;
    A+=(xk-A)/k;
    Q+=(xk-oldA)*(xk-A);
  }
  
  return sqrt(Q/(limit-1));
}
