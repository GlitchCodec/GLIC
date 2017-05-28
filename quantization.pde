void quantize(Planes planes, int p, Segment s, float val, boolean forward) {
  if (val > 1) {
    for (int x=0; x<s.size; x++) {
      for (int y=0; y<s.size; y++) {
        float col = planes.get(p, x+s.x, y+s.y); 

        if (forward)
          col = col / val;
        else
          col = col * val;

        planes.set(p, x+s.x, y+s.y, (int)round(col));
      }
    }
  }
}