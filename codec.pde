import com.github.jinahya.bit.io.*;
import java.io.*;

boolean do_skip_header = false;

class CodecConfig {
  // Color space to operate
  int colorspace = HWB;
  // color outside image, always RGB
  color color_outside = color(128, 128, 128);

  // Segmentation configuration.
  // Minimum/maximum block size for each channel
  int[] min_block_size = {
    2, 2, 2
  };
  int[] max_block_size = {
    256, 256, 256
  };
  // Precision (lower better), values between 5 and 50+
  float[] segmentation_precision = {
    15, 15, 15
  };

  // Final encoding configuration
  int[] encoding_method = {
    0, 0, 0
  };

  // Global prediction method
  int[] prediction_method = {
    9, 9, 9
  };

  // prediction quantization 0-255
  int[] quantization_value = {
    110, 110, 110
  };

  int[] clamp_method = {
    0, 0, 0
  };

  // type of transformation
  int[] transform_type = {
    0, 0, 0
  };

  // Transform method
  int[] transform_method = {
    29, 29, 29
  };

  // transform compression 0-255
  float[] transform_compress = {
    0, 0, 0
  };

  int[] transform_scale = {
    20, 20, 20
  };

  public CodecConfig() {
    super();
  }
}

CodecConfig ccfg = new CodecConfig();

float trans_compression_value(float v) {
  return 50*sq(v/255.0);
}

float quant_value(int v) {
  return v/2.0;
}

PImage encode(PImage img, String fname) {
  System.gc();
  img.loadPixels();
  try {
    println("Encoding started");
    GlicCodecWriter gcw = new GlicCodecWriter(fname, img.width, img.height);
    println("Write first header");
    // fourcc, width, height, colorspace, border color
    gcw.writeFirstHeader();

    println("Color space: "+getColorspaceName(ccfg.colorspace));

    // prepare transform method and type, skip TRANS_NONE (0)
    for (int p=0; p<3; p++) {
      ccfg.transform_method[p] = ccfg.transform_method[p]==WAVELET_RANDOM ? (int)random(1, WAVELETNO) : ccfg.transform_method[p];
      ccfg.transform_type[p] = ccfg.transform_type[p]==TRANSTYPE_RANDOM ? (int)random(TRANSTYPENO) : ccfg.transform_type[p];
    }

    println("Write second header");
    // prediction method, quantization and clamping, transformations and final encoding per channel
    gcw.writeSecondHeader();

    // img -> planes structure
    Planes planes = new Planes(img.pixels, img.width, img.height, ccfg.colorspace);

    // Segmentation is stored as quad tree encoded binary (1 - go deeper, 0 - leaf)
    // where to store all segments
    ArrayList<Segment> segments[] = new ArrayList[3];

    gcw.writeSegmentationMark();
    for (int p=0; p<3; p++) {
      println("Channel "+p+" segmentation. Structure.");

      gcw.writeChannelMark(p);

      ByteArrayOutputStream segm_arr_out = new ByteArrayOutputStream();
      DefaultBitOutput segm_out = new DefaultBitOutput(new StreamByteOutput(segm_arr_out));

      segments[p] = makeSegmentation(segm_out, planes, p, ccfg.min_block_size[p], ccfg.max_block_size[p], ccfg.segmentation_precision[p]);
      println("Created " + segments[p].size() + " segments.");

      // allign to byte
      segm_out.align(1);
      // store size to update later
      gcw.segmentation_sizes[p]=segm_arr_out.size();

      gcw.writeArray(segm_arr_out.toByteArray(), segm_arr_out.size());
    }

    println("Store segmentation visualization");
    isegm = visualize_segmentation(segments, planes);

    // set separator, 512 bytes of 0xff
    gcw.writeSeparator(512, (byte)0xff);

    // process of encoding involves decoding, we have to store somewhere only encoded data
    Planes result = planes.clone();
    Planes planes_pred = planes.clone();

    println("Data encoding: predictions and transformations");
    for (int p=0; p<3; p++) {

      Wavelet wavelet = ccfg.transform_method[p] == WAVELET_NONE ? null : createWavelet(ccfg.transform_method[p]);
      WaveletTransform trans = wavelet == null ? null : createTransform(ccfg.transform_type[p], wavelet);
      Compressor comp = ccfg.transform_compress[p] > 0 ? new CompressorMagnitude(trans_compression_value(ccfg.transform_compress[p])) : null;

      println("Wavelet for plane " + p + " -> " + (wavelet==null?"NONE":wavelet.getName()));
      println("Transformation for plane " + p + " -> " + (trans==null?"NONE":trans.getName()));

      println("Prediction for plane " + p + " -> " + predict_name(ccfg.prediction_method[p]));

      // gather SAD/BSAD statistics
      pred_sad_stats = new int[MAX_PRED];

      float pq = quant_value(ccfg.quantization_value[p]);

      for (Segment s : segments[p]) {

        // predict

        int[][] pred = predict(ccfg.prediction_method[p], planes, p, s);
        // calculate residuals and clamp
        planes.subtract(p, s, pred, ccfg.clamp_method[p]);

        // quantize result
        if (pq > 0) quantize(planes, p, s, pq, true); 

        // if transformation applied transform and compress
        // maximum value after transformation is s.size * max_value
        try {
          if (trans != null) {
            double[][] tr = planes.get(p, s);
            tr = trans.forward(tr);

            if (comp != null) {
              tr = comp.compress(tr);
            }

            // store result as ints
            for (int x=0; x<s.size; x++) {
              for (int y=0; y<s.size; y++) {
                planes.set(p, s.x+x, s.y+y, round((float)((tr[x][y]*ccfg.transform_scale[p])/(float)s.size)));
              }
            }
          }
        } 
        catch (JWaveException e) {
          // ignore
        }

        // store encoding value in result planes to save later
        for (int x=0; x<s.size; x++) {
          for (int y=0; y<s.size; y++) {
            result.set(p, s.x+x, s.y+y, planes.get(p, s.x+x, s.y+y));
          }
        }

        // decompress now
        // wavelets
        try {
          if (trans != null) {
            double[][] tr = new double[s.size][s.size];

            for (int xx=0; xx<tr.length; xx++) {
              for (int yy=0; yy<tr.length; yy++) {
                tr[xx][yy] = (s.size*planes.get(p, s.x+xx, s.y+yy))/(float)ccfg.transform_scale[p];
              }
            }

            tr = trans.reverse(tr);
            planes.set(p, s, tr, ccfg.clamp_method[p]);
          }
        } 
        catch (JWaveException e) {
          // ignore
        }

        // reverse quantization
        if (pq > 0) quantize(planes, p, s, pq, false);
        // add back residuals and clamp

        pred = predict(s.pred_type, planes, p, s);
        planes.add(p, s, pred, ccfg.clamp_method[p]);

        for (int x=0; x<s.size; x++) {
          for (int y=0; y<s.size; y++) {
            planes_pred.set(p, s.x+x, s.y+y, pred[x][y]);
          }
        }
      }
    }

    ipred = planes_pred.toImage();
    planes_pred=null;

    gcw.writePredictDataMark();
    // store another config, prediction additional info
    for (int p=0; p<3; p++) {
      println("Channel "+p+" segmentation. Configuration.");
      gcw.writeChannelMark(p);
      gcw.writeSegmentsData(p, segments[p]);
    }

    gcw.writeSeparator(512, (byte)0xff);
    gcw.writeDataMark();
    println("Encoding data"); 
    for (int p=0; p<3; p++) {   
      gcw.writeChannelMark(p);   
      gcw.data_sizes[p] = gcw.writeData(ccfg.encoding_method[p], result, p, segments[p]);
    }
    println(gcw.data_sizes);

    gcw.close();
    
    result = null;
    PImage rrr = planes.toImage();
    
    println("FINISHED");
    println("");
    
    return rrr;
  } 
  catch (Exception e) {
    println("Encoding failed");
    e.printStackTrace();
  }
  return null;
}

PImage decode(String fname) {
  System.gc();
  if (do_skip_header) readValues();
  println("Decoding started");
  try {
    GlicCodecReader gcr = new GlicCodecReader(fname);
    println("Read first header");
    gcr.readFirstHeader();
    println("Color space: "+getColorspaceName(gcr.colorspace));

    println("Read second header");
    gcr.readSecondHeader();

    println("Reading segmentation structure");

    Planes planes = new Planes(gcr.w, gcr.h, gcr.colorspace, new RefColor(gcr.color_outside[0], gcr.color_outside[1], gcr.color_outside[2], gcr.colorspace));

    ArrayList<Segment> segments[] = new ArrayList[4];

    gcr.skip(13); // segmentation mark
    for (int p=0; p<3; p++) {
      println("Channel "+p+" segmentation");

      gcr.skip(4);

      byte[] segmentation_info = gcr.readArray(gcr.segmentation_sizes[p]);
      ArrayByteInput segm_arr_in = new ArrayByteInput(segmentation_info, 0, segmentation_info.length);
      DefaultBitInput segm_in = new DefaultBitInput(segm_arr_in);

      segments[p] = readSegmentation(segm_in, planes);
    }

    gcr.skip(512);
    println("Reading segmentation data");
    gcr.skip(12); // predict data mark
    for (int p=0; p<3; p++) {
      gcr.skip(4);
      gcr.readSegmentsData(p, segments[p]);
    }

    gcr.skip(512);
    gcr.skip(10); // image data mark
    println("Decoding data"); 
    for (int p=0; p<3; p++) {
      gcr.skip(4);
      gcr.readData(gcr.encoding_method[p], planes, p, segments[p]);
    }

    Planes planes_pred = planes.clone();

    for (int p=0; p<3; p++) {

      Wavelet wavelet = gcr.transform_method[p] == WAVELET_NONE ? null : createWavelet(gcr.transform_method[p]);
      WaveletTransform trans = wavelet == null ? null : createTransform(gcr.transform_type[p], wavelet);

      println("Wavelet for plane " + p + " -> " + (wavelet==null?"NONE":wavelet.getName()));
      println("Transformation for plane " + p + " -> " + (trans==null?"NONE":trans.getName()));

      println("Prediction for plane " + p + " -> " + predict_name(gcr.prediction_method[p]));

      float pq = quant_value(gcr.quant_value[p]);
      for (Segment s : segments[p]) {

        try {
          if (trans != null) {
            double[][] tr = new double[s.size][s.size];

            for (int xx=0; xx<tr.length; xx++) {
              for (int yy=0; yy<tr.length; yy++) {
                tr[xx][yy] = (s.size*planes.get(p, s.x+xx, s.y+yy))/(float)gcr.transform_scale[p];
              }
            }

            tr = trans.reverse(tr);
            planes.set(p, s, tr, gcr.clamp_method[p]);
          }
        } 
        catch (JWaveException e) {
          // ignore
        }

        if (pq>0) quantize(planes, p, s, pq, false);

        int[][] pred = predict(s.pred_type, planes, p, s);
        planes.add(p, s, pred, gcr.clamp_method[p]);

        for (int x=0; x<s.size; x++) {
          for (int y=0; y<s.size; y++) {
            planes_pred.set(p, s.x+x, s.y+y, pred[x][y]);
          }
        }
      }
    }

    gcr.close();

    println("Store segmentation visualization");
    isegm = visualize_segmentation(segments, planes);

    ipred = planes_pred.toImage();

    println("FINISHED");
    println("");

    return planes.toImage();
  } 
  catch (Exception e) {
    println("Decoding failed");
    e.printStackTrace();
  }
  return null;
}

PImage visualize_segmentation(ArrayList<Segment> segments[], Planes source) {
  Planes res = source.clone();
  for (int p=0; p<3; p++) {
    for (Segment ss : segments[p]) {
      int v = source.get(p, ss.x+(ss.size>>1), ss.y+(ss.size>>1));
      for (int x=0; x<ss.size; x++) {
        for (int y=0; y<ss.size; y++) {
          res.set(p, ss.x+x, ss.y+y, v);
        }
      }
    }
  }
  return res.toImage();
}

class GlicCodecReader {
  DataInputStream o;
  String filename; 
  int w, h;
  int colorspace;
  int[] color_outside = {
    0, 0, 0
  };
  int[] segmentation_sizes = {
    0, 0, 0, 0
  };
  int[] data_sizes = {
    0, 0, 0, 0
  };
  int[] segmdata_sizes = {
    0, 0, 0, 0
  };
  // Final encoding configuration
  int[] encoding_method = {
    0, 0, 0
  };
  // Global prediction method
  int[] prediction_method = {
    0, 0, 0
  };
  int[] clamp_method = {
    0, 0, 0
  };
  // prediction quantization 0-255
  int[] quant_value = {
    0, 0, 0
  };
  // Transform method
  int[] transform_method = {
    0, 0, 0
  };
  // type of transformation
  int[] transform_type = {
    0, 0, 0
  };

  int[] transform_scale = {
    0, 0, 0
  };

  public GlicCodecReader(String filename) {
    this.filename = filename;
    o = new DataInputStream(new BufferedInputStream(createInput(filename)));
  }

  byte[] readArray(int size) throws IOException {
    byte[] res = new byte[size];
    try {
      o.readFully(res, 0, size);
    } 
    catch (java.io.EOFException e) {
      // ignore
    }
    return res;
  }

  void readSegmentsData(int p, ArrayList<Segment> segments) throws IOException {
    DataInputStream in = new DataInputStream(new ByteArrayInputStream(readArray(segmdata_sizes[p])));
    try {
      for (Segment s : segments) {
        s.pred_type = in.readUnsignedByte();
        s.pred_type = s.pred_type == PRED_NONE ? prediction_method[p] : s.pred_type;
        s.refx = in.readShort();
        s.refy = in.readShort();
        s.refa = in.readUnsignedByte() % 3;
        s.angle = (float)in.readShort()/0x7000;
      }
    } 
    catch (EOFException e) {
      // ignore
    }
    finally {
      in.close();
    }
  }

  void readData(int method, Planes p, int pno, ArrayList<Segment> s) {
    switch (method) {
    case ENCODING_PACKED:
      decode_packed(p, pno, s); 
      break;  
    case ENCODING_RLE:
      decode_rle(p, pno, s); 
      break;  
    default:
      decode_raw(p, pno, s);
    }
  }

  void decode_raw(Planes p, int pno, ArrayList<Segment> s) {
    try {
      int idx=0;
      for (Segment segm : s) {
        for (int x=0; x<segm.size; x++) {
          for (int y=0; y<segm.size; y++) {
            if (idx < data_sizes[pno]) {
              p.set(pno, segm.x+x, segm.y+y, o.readInt());
              idx+=4;
            }
          }
        }
      }
    } 
    catch (IOException e) {
      println("decode raw failed");
      // ignore
    }
  }

  void decode_packed(Planes p, int pno, ArrayList<Segment> s) {
    try {
      byte[] d = readArray(data_sizes[pno]);
      DefaultBitInput in = new DefaultBitInput(new ArrayByteInput(d, 0, d.length));

      int bits = (int)ceil(log(transform_scale[pno])/log(2.0));


      for (Segment segm : s) {
        for (int x=0; x<segm.size; x++) {
          for (int y=0; y<segm.size; y++) {
            p.set(pno, segm.x+x, segm.y+y, decodePackedBits(in, pno, bits));
          }
        }
      }
    } 
    catch(EOFException e) {
      println("decode packed failed (EOF)");
      // ignore
    } 
    catch(IOException e) {
      println("decode packed failed (IO)");
      // ignore
    }
    catch(IllegalStateException e) {
      println("decode packed failed");
      // ignore
    }
  }

  void decode_rle(Planes p, int pno, ArrayList<Segment> s) {
    try {
      byte[] d = readArray(data_sizes[pno]);
      DefaultBitInput in = new DefaultBitInput(new ArrayByteInput(d, 0, d.length));

      int bits = (int)ceil(log(transform_scale[pno])/log(2.0));
      int currentval = 0;
      boolean do_read_type = true;
      int currentcnt = 0;


      for (Segment segm : s) {
        for (int x=0; x<segm.size; x++) {
          for (int y=0; y<segm.size; y++) {

            if (do_read_type) {
              if (in.readBoolean()) { // size
                currentcnt = in.readInt(true, 7)+2;
                do_read_type = false;
              }
              currentval = decodePackedBits(in, pno, bits);
            }
            p.set(pno, segm.x+x, segm.y+y, currentval);
            currentcnt--;
            if (currentcnt <= 0) {
              do_read_type = true;
            }
          }
        }
      }
    } 
    catch(EOFException e) {
      println("decode rle failed (EOF)");
      // ignore
    } 
    catch(IOException e) {
      println("decode rle failed (IO)");
      // ignore
    }
    catch(IllegalStateException e) {
      println("decode rle failed");
      // ignore
    }
  }

  int decodePackedBits(DefaultBitInput in, int pno, int bits) throws IOException {
    if (transform_method[pno] == WAVELET_NONE) {
      if (clamp_method[pno] == CLAMP_NONE) {
        return in.readInt(false, 9);
      } else if (clamp_method[pno] == CLAMP_MOD256) {
        return in.readInt(true, 8);
      }
    } else {
      return in.readInt(false, bits+1);
    }
    return 0;
  } 

  void skip(int bytes) {
    try {
      for (int i=0; i<bytes; i++) o.readByte();
    } 
    catch (IOException e) {
      println("skip failed");
      // ignore
    }
  }

  void readFirstHeader() throws IOException {
    // GLIC
    skip(4);

    // width, height
    w = max(64,abs(o.readInt())%8192); // 4
    h = max(64,abs(o.readInt())%8192); // 4

    // colorspace
    colorspace = o.readUnsignedByte(); // 1
    if (do_skip_header) colorspace = ccfg.colorspace;

    // color outside image
    color_outside[0] = o.readUnsignedByte();
    color_outside[1] = o.readUnsignedByte();
    color_outside[2] = o.readUnsignedByte();
    if (do_skip_header) {
      color_outside[0] = getR(ccfg.color_outside);
      color_outside[1] = getG(ccfg.color_outside);
      color_outside[2] = getB(ccfg.color_outside);
    }

    segmentation_sizes[0] = o.readInt()&0x7ffff;
    segmentation_sizes[1] = o.readInt()&0x7ffff;
    segmentation_sizes[2] = o.readInt()&0x7ffff;
    segmentation_sizes[3] = o.readInt()&0x7ffff;

    segmdata_sizes[0] = o.readInt()&0xffffff;
    segmdata_sizes[1] = o.readInt()&0xffffff;
    segmdata_sizes[2] = o.readInt()&0xffffff;
    segmdata_sizes[3] = o.readInt()&0xffffff;

    data_sizes[0] = o.readInt()&0x3ffffff;
    data_sizes[1] = o.readInt()&0x3ffffff;
    data_sizes[2] = o.readInt()&0x3ffffff;
    data_sizes[3] = o.readInt()&0x3ffffff;

    println("Segmentation sizes");
    println(segmentation_sizes);

    println("Segmentation data sizes");
    println(segmdata_sizes);

    println("Data sizes");
    println(data_sizes);

    skip(128-16-16-16-16);
  }

  void readSecondHeader() throws IOException {
    for (int p=0; p<3; p++) {
      skip(4);

      prediction_method[p] = o.readUnsignedByte();
      quant_value[p] = o.readUnsignedByte();
      clamp_method[p] = o.readUnsignedByte();

      transform_method[p] = o.readUnsignedByte();
      transform_type[p] = o.readUnsignedByte();

      transform_scale[p] = o.readInt();

      encoding_method[p] = o.readUnsignedByte();

      if (do_skip_header) {
        println(separate_channels_toggle);
        int pp = separate_channels_toggle ? p : 0;
        prediction_method[p] = max(0,ccfg.prediction_method[pp]);
        quant_value[p] = ccfg.quantization_value[pp];
        clamp_method[p] = ccfg.clamp_method[pp];

        transform_method[p] = ccfg.transform_method[pp];
        transform_type[p] = ccfg.transform_type[p];

        transform_scale[p] = ccfg.transform_scale[pp];

        encoding_method[p] = ccfg.encoding_method[pp];
      }

      skip(32-4-6-4);
    }
  }


  void close() throws IOException {
    o.close();
  }
}


class GlicCodecWriter {
  DataOutputStream o;
  String filename; 
  int w, h;
  int current_written;

  int[] segmentation_sizes = {
    0, 0, 0, 0
  };
  int[] data_sizes = {
    0, 0, 0, 0
  };
  int[] segmdata_sizes = {
    0, 0, 0, 0
  };

  public GlicCodecWriter(String filename, int w, int h) {
    this.w = w;
    this.h = h;
    this.filename = filename;
    o = new DataOutputStream(new BufferedOutputStream(createOutput(filename)));
    current_written = o.size();
  }

  int writeData(int method, Planes p, int pno, ArrayList<Segment> s) throws IOException {
    int current = o.size();

    switch (method) {
    case ENCODING_PACKED: 
      encode_packed(p, pno, s); 
      break;
    case ENCODING_RLE:
      encode_rle(p, pno, s);
      break;
    default:
      encode_raw(p, pno, s);
    }

    return (o.size() - current);
  }

  void encode_raw(Planes p, int pno, ArrayList<Segment> s) throws IOException {
    for (Segment segm : s) {
      for (int x=0; x<segm.size; x++) {
        for (int y=0; y<segm.size; y++) {
          o.writeInt(p.get(pno, segm.x+x, segm.y+y));
        }
      }
    }
  }

  void encode_packed(Planes p, int pno, ArrayList<Segment> s) throws IOException {
    DefaultBitOutput out = new DefaultBitOutput(new StreamByteOutput(o));

    int bits = (int)ceil(log(ccfg.transform_scale[pno])/log(2.0));

    for (Segment segm : s) {
      for (int x=0; x<segm.size; x++) {
        for (int y=0; y<segm.size; y++) {
          emitPackedBits(out, pno, bits, p.get(pno, segm.x+x, segm.y+y));
        }
      }
    }
    out.align(1);
  }

  void encode_rle(Planes p, int pno, ArrayList<Segment> s) throws IOException {
    DefaultBitOutput out = new DefaultBitOutput(new StreamByteOutput(o));

    int bits = (int)ceil(log(ccfg.transform_scale[pno])/log(2.0));
    int currentval = 0;
    boolean firstval = true;
    int currentcnt = 0;

    for (Segment segm : s) {
      for (int x=0; x<segm.size; x++) {
        for (int y=0; y<segm.size; y++) {
          int val = p.get(pno, segm.x+x, segm.y+y);

          if (firstval) {
            currentval = val;
            currentcnt = 1;
            firstval = false;
          } else {
            if (currentval != val || currentcnt == 129) {
              if (currentcnt == 1) {
                out.writeBoolean(false);
              } else {
                out.writeBoolean(true);
                out.writeInt(true, 7, currentcnt-2);
              }
              emitPackedBits(out, pno, bits, currentval);
              currentval = val;
              currentcnt = 1;
            } else {
              currentcnt++;
            }
          }
        }
      }
    }

    if (currentval == 1) {
      out.writeBoolean(false);
    } else {
      out.writeBoolean(true);
      out.writeInt(true, 7, currentcnt-2);
    }
    emitPackedBits(out, pno, bits, currentval);
    out.align(1);
  }

  void emitPackedBits(DefaultBitOutput out, int pno, int bits, int val) throws IOException {
    if (ccfg.transform_method[pno] == WAVELET_NONE) {
      if (ccfg.clamp_method[pno] == CLAMP_NONE) {
        out.writeInt(false, 9, val);
      } else if (ccfg.clamp_method[pno] == CLAMP_MOD256) {
        out.writeInt(true, 8, val);
      }
    } else {
      out.writeInt(false, bits+1, val);
    }
  } 

  void writeSegmentsData(int pno, ArrayList<Segment> segments) throws IOException {
    ByteArrayOutputStream baus = new ByteArrayOutputStream();
    DataOutputStream out = new DataOutputStream(baus);
    for (Segment s : segments) {
      int pred_type = ccfg.prediction_method[pno] < 0 ? s.pred_type : PRED_NONE; // if prediction is different than NONE, store it, other cases are NONE
      out.writeByte(pred_type);
      out.writeShort(s.refx);
      out.writeShort(s.refy);
      out.writeByte(s.refa);
      out.writeShort((int)(0x7000 * s.angle) );
    }
    out.flush();
    out.close();
    segmdata_sizes[pno] = baus.size();
    writeArray(baus.toByteArray(), baus.size());
  }

  void align(int bytes) throws IOException {
    int to_write = bytes - (o.size()-current_written);
    writeSeparator(to_write, 0);
    current_written = o.size();
  }

  void writeArray(byte[] a, int size) throws IOException {
    o.write(a, 0, size);
  }

  void writeSeparator(int size, int val) throws IOException {
    for (int i=0; i<size; i++) {
      o.writeByte(val);
    }
  }

  void writeChannelMark(int ch) throws IOException {
    o.writeByte(0x43);
    o.writeByte(0x48);
    o.writeByte(0x30);
    o.writeByte(0x31+ch);
  }

  void writeSegmentationMark() throws IOException { //12
    o.writeByte(0x53);
    o.writeByte(0x45);
    o.writeByte(0x47);
    o.writeByte(0x4D);
    o.writeByte(0x45);
    o.writeByte(0x4E);
    o.writeByte(0x54);
    o.writeByte(0x41);
    o.writeByte(0x54);
    o.writeByte(0x49);
    o.writeByte(0x4F);
    o.writeByte(0x4E);
    o.writeByte(0x20);
  }

  void writePredictDataMark() throws IOException { //11
    o.writeByte(0x50);
    o.writeByte(0x52);
    o.writeByte(0x45);
    o.writeByte(0x44);
    o.writeByte(0x49);
    o.writeByte(0x43);
    o.writeByte(0x54);
    o.writeByte(0x44);
    o.writeByte(0x41);
    o.writeByte(0x54);
    o.writeByte(0x41);
    o.writeByte(0x20);
  }

  void writeDataMark() throws IOException { //9
    o.writeByte(0x49);
    o.writeByte(0x4D);
    o.writeByte(0x41);
    o.writeByte(0x47);
    o.writeByte(0x45);
    o.writeByte(0x44);
    o.writeByte(0x41);
    o.writeByte(0x54);
    o.writeByte(0x41);
    o.writeByte(0x20);
  }
  void writeFirstHeader() throws IOException {
    // GLIC
    o.writeByte(0x47);
    o.writeByte(0x4C);
    o.writeByte(0x49);
    o.writeByte(0x43);

    // width, height
    o.writeInt(w); // 4
    o.writeInt(h); // 4

    // colorspace
    o.writeByte(ccfg.colorspace); // 1

    // color outside image
    o.writeByte(getR(ccfg.color_outside)); // 1
    o.writeByte(getG(ccfg.color_outside)); // 1
    o.writeByte(getB(ccfg.color_outside)); // 1
    align(128);
  }

  void writeSecondHeader() throws IOException {
    for (int p=0; p<3; p++) {
      writeChannelMark(p);

      int pred = ccfg.prediction_method[p];
      // write PRED_NONE if random or sad/bsad, specific prediction method will be stored separately
      if (pred<0) pred = PRED_NONE;
      o.writeByte(pred); // what prediction
      o.writeByte(ccfg.quantization_value[p]); // quantization value
      o.writeByte(ccfg.clamp_method[p]); // how to clamp / encode residuals

      o.writeByte(ccfg.transform_method[p]); // which wavelet
      o.writeByte(ccfg.transform_type[p]); // which transform
      o.writeInt(ccfg.transform_scale[p]);

      o.writeByte(ccfg.encoding_method[p]); // final encoding / compression

      align(32);
    }
  }

  void size() throws IOException {
    o.size();
  }

  void close() throws IOException {
    o.flush();
    o.close();

    RandomAccessFile raf = new RandomAccessFile(sketchPath(filename), "rw");
    raf.seek(16);
    raf.writeInt(segmentation_sizes[0]);
    raf.writeInt(segmentation_sizes[1]);
    raf.writeInt(segmentation_sizes[2]);
    raf.writeInt(segmentation_sizes[3]);
    raf.writeInt(segmdata_sizes[0]);
    raf.writeInt(segmdata_sizes[1]);
    raf.writeInt(segmdata_sizes[2]);
    raf.writeInt(segmdata_sizes[3]);
    raf.writeInt(data_sizes[0]);
    raf.writeInt(data_sizes[1]);
    raf.writeInt(data_sizes[2]);
    raf.writeInt(data_sizes[3]);
    raf.close();

    println("Segmentation sizes");
    println(segmentation_sizes);

    println("Segmentation data sizes");
    println(segmdata_sizes);

    println("Data sizes");
    println(data_sizes);
  }
}

