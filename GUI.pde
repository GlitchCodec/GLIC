import controlP5.*;
import java.text.SimpleDateFormat;
import java.util.Date;

ControlP5 cp5;

CheckBox separate_channels;
CheckBox batch, skip_header, skip_session;
Tab ch1, ch2, ch3;

Controller ch1mn, ch1mx, ch2mn, ch2mx, ch3mn, ch3mx;
Slider co_r, co_g, co_b;
ScrollableList sl_cs, presets_list;

Button lbutton, ebutton, dbutton;
ButtonBar bbar;

Textfield save_filename, glic_filename, preset_name;

String[] bbar_names = new String[] {
  "Image", "Segm", "Pred", "Result"
};

HashMap<String, ControllerInterface>[] chmap = new HashMap[3];

boolean separate_channels_toggle = false;
boolean do_skip_session = false;

int presets_count = 0;
String current_preset = null;

SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");

void gui() {
  cp5 = new ControlP5(this);

  Tab global = cp5.getTab("default").setLabel("Global config");

  ch1 = cp5.addTab("Channel 1").setLabel("All channels");
  ch2 = cp5.addTab("Channel 2").setVisible(false);
  ch3 = cp5.addTab("Channel 3").setVisible(false);

  cp5.addLabel("color_outside_label")
    .setText("Color outside")
      .setPosition(10, 150)
        .moveTo(global);

  co_r = cp5.addSlider("R")
    .setPosition(10, 160)
      .setWidth(170)
        .setRange(0, 255)
          .setValue(128)
            .setScrollSensitivity(0.02)
              .moveTo(global);

  co_g = cp5.addSlider("G")
    .setPosition(10, 170)
      .setWidth(170)
        .setRange(0, 255)
          .setValue(128)
            .setScrollSensitivity(0.02)
              .moveTo(global);

  co_b = cp5.addSlider("B")
    .setPosition(10, 180)
      .setWidth(170)
        .setRange(0, 255)
          .setValue(128)
            .setScrollSensitivity(0.02)
              .moveTo(global);

  separate_channels = cp5.addCheckBox("separate_channels")
    .setPosition(10, 200)
      .addItem("Separate channels", 1)
        .deactivate(0)
          .moveTo(global);

  batch = cp5.addCheckBox("batch")
    .setPosition(110, 200)
      .addItem("Batch run", 1)
        .deactivate(0)
          .moveTo(global);

  sl_cs = cp5.addScrollableList("Color space")
    .setType(ScrollableList.LIST)
      .setPosition(10, 20)
        .setSize(180, 120)
          .moveTo(global);

  for (int i=0; i<COLORSPACES; i++) {
    sl_cs.addItem(getColorspaceName(i), i);
  }

  sl_cs.getItem(1).put("state", true);
  sl_cs.setValue(1);

  lbutton = cp5.addButton("load_button")
    .setPosition(10, 220)
      .setSize(120, 20)
        .setLabel("LOAD IMAGE (ctrl-l)")
          .moveTo(global);

  cp5.addButton("reload_image")
    .setPosition(140, 220)
      .setSize(50, 20)
        .setLabel("RELOAD")
          .moveTo(global);          

  ebutton = cp5.addButton("encode_button")
    .setPosition(10, 250)
      .setSize(180, 20)
        .setLabel("ENCODE (ctrl-e)")
          .moveTo(global);

  skip_header = cp5.addCheckBox("skip_header")
    .setPosition(10, 280)
      .addItem("Use config during decoding (skip header)", 1)
        .deactivate(0)
          .moveTo(global);

  dbutton = cp5.addButton("decode_button")
    .setPosition(10, 290)
      .setSize(180, 20)
        .setLabel("DECODE (ctrl-d)")
          .moveTo(global);

  cp5.addButton("save_button")
    .setPosition(10, 320)
      .setSize(180, 20)
        .setLabel("SAVE RESULT (ctrl-s)")
          .moveTo(global);

  save_filename = cp5.addTextfield("Save filename")
    .setPosition(10, 350)
      .setWidth(180)
        .setAutoClear(false)
          .moveTo(global);

  glic_filename = cp5.addTextfield("GLIC filename")
    .setPosition(10, 390)
      .setWidth(180)
        .setAutoClear(false)
          .moveTo(global);

  skip_session = cp5.addCheckBox("skip_session")
    .setPosition(10, 430)
      .addItem("Skip generating session id", 1)
        .deactivate(0)
          .moveTo(global);

  bbar = cp5.addButtonBar("image_switch")
    .setPosition(10, 450)
      .setWidth(180)
        .addItems(bbar_names)
          .moveTo(global);

  cp5.addButton("keep_image")
    .setPosition(10, 470)
      .setWidth(180)
        .setLabel("KEEP IMAGE")
          .moveTo(global);

  cp5.addLabel("presets_label")
    .setText("Presets")
      .setPosition(10, 500)
        .moveTo(global);

  presets_list = cp5.addScrollableList("presets")
    .setType(ScrollableList.LIST)
      .setPosition(10, 510)
        .setSize(180, 120)
          .moveTo(global);

  updatePresets();

  preset_name = cp5.addTextfield("Preset name")
    .setPosition(10, 650)
      .setWidth(180)
        .setAutoClear(false)
          .moveTo(global);  

  cp5.addButton("save_preset")
    .setPosition(10, 690)
      .setSize(180, 20)
        .setLabel("SAVE PRESET")
          .moveTo(global);

  chmap[0] = addToTab(ch1);
  chmap[1] = addToTab(ch2);
  chmap[2] = addToTab(ch3);

  ch1mn = cp5.getController(ch1.getName() + "min");
  ch1mx = cp5.getController(ch1.getName() + "max");
  ch2mn = cp5.getController(ch2.getName() + "min");
  ch2mx = cp5.getController(ch2.getName() + "max");
  ch3mn = cp5.getController(ch3.getName() + "min");
  ch3mx = cp5.getController(ch3.getName() + "max");
}

HashMap<String, ControllerInterface> addToTab(Tab t) {
  HashMap<String, ControllerInterface> h = new HashMap<String, ControllerInterface>();

  cp5.addLabel(t.getName() + "segmentation_label")
    .setText("Segmentation, min/max are powers of 2")
      .setPosition(10, 20)
        .moveTo(t);

  Slider mn_blocksize = cp5.addSlider(t.getName() + "min")
    .setLabel("MIN")
      .setPosition(10, 30)
        .setWidth(160)
          .setRange(1, 9)
            .setNumberOfTickMarks(9)
              .showTickMarks(false)
                .setValue(2)
                  .moveTo(t);  

  h.put("min", mn_blocksize);

  Slider mx_blocksize = cp5.addSlider(t.getName() + "max")
    .setLabel("MAX")
      .setPosition(10, 40)
        .setWidth(160)
          .setRange(1, 9)
            .setNumberOfTickMarks(9)
              .showTickMarks(false)
                .setValue(8)
                  .moveTo(t);

  h.put("max", mx_blocksize);

  Slider thr_block = cp5.addSlider(t.getName() + "thr")
    .setLabel("THR")
      .setPosition(10, 50)
        .setWidth(160)
          .setRange(5, 250)
            .setValue(15)
              .setScrollSensitivity(0.02)
                .moveTo(t);

  h.put("thr", thr_block);

  ScrollableList pred = cp5.addScrollableList(t.getName() + "pred")
    .setLabel("Predictions")
      .setType(ScrollableList.LIST)
        .setPosition(10, 70)
          .setSize(180, 120)
            .moveTo(t);

  h.put("pred", pred);

  for (int i=0; i<MAX_PRED; i++) {
    pred.addItem(predict_name(i), i);
  }
  pred.addItem(predict_name(-1), -1);
  pred.addItem(predict_name(-2), -2);
  pred.addItem(predict_name(-3), -3);

  pred.getItem(7).put("state", true);
  pred.setValue(7);

  cp5.addLabel(t.getName()+"quantization_label")
    .setText("Quantization value")
      .setPosition(10, 200)
        .moveTo(t);

  Slider quant = cp5.addSlider(t.getName() + "quant")
    .setLabel("")
      .setPosition(10, 210)
        .setWidth(180)
          .setRange(0, 255)
            .setValue(0)
              .setScrollSensitivity(0.02)
                .moveTo(t);

  h.put("quant", quant);

  RadioButton clamp = cp5.addRadioButton(t.getName() + "clamp")
    .setPosition(10, 230)
      .addItem(t.getName() + "CLAMP_NONE", CLAMP_NONE)
        .addItem(t.getName() + "CLAMP_MOD256", CLAMP_MOD256)
          .activate(0)
            .moveTo(t);

  clamp.getItem(0).setLabel("CLAMP_NONE");
  clamp.getItem(1).setLabel("CLAMP_MOD256");

  h.put("clamp", clamp);

  ScrollableList trans = cp5.addScrollableList(t.getName() + "trans")
    .setLabel("Wavelet")
      .setType(ScrollableList.LIST)
        .setPosition(10, 260)
          .setSize(180, 120)
            .moveTo(t);

  h.put("trans", trans);

  trans.addItem("NONE", 0);
  for (int i=1; i<WAVELETNO; i++) {
    trans.addItem(getWavelet(i).getName(), i);
  }
  trans.addItem("RANDOM", -1);

  trans.getItem(0).put("state", true);
  trans.setValue(0);

  cp5.addLabel(t.getName() + "compression_label")
    .setText("Compression")
      .setPosition(10, 390)
        .moveTo(t);

  Slider compress = cp5.addSlider(t.getName() + "compress")
    .setLabel("")
      .setPosition(10, 400)
        .setWidth(180)
          .setRange(0, 255)
            .setValue(0)
              .setScrollSensitivity(0.02)
                .moveTo(t);

  h.put("compress", compress);

  cp5.addLabel(t.getName() + "scaler_label")
    .setText("Scale transformation (2^x)")
      .setPosition(10, 420)
        .moveTo(t);

  Slider scaler = cp5.addSlider(t.getName() + "scale")
    .setLabel("")
      .setPosition(10, 430)
        .setWidth(180)
          .setRange(2, 24)
            .setValue(20)
              .setScrollSensitivity(0.02)
                .moveTo(t);

  h.put("scale", scaler);

  RadioButton ttype = cp5.addRadioButton(t.getName() + "ttype")
    .setPosition(10, 450)
      .addItem(t.getName()+"TRANSTYPE_FWT", TRANSTYPE_FWT)
        .addItem(t.getName()+"TRANSTYPE_WPT", TRANSTYPE_WPT)
          .addItem(t.getName()+"TRANSTYPE_RANDOM", -1)
            .activate(0)
              .moveTo(t);

  ttype.getItem(0).setLabel("TRANSTYPE_FWT");
  ttype.getItem(1).setLabel("TRANSTYPE_WPT");
  ttype.getItem(2).setLabel("TRANSTYPE_RANDOM");

  h.put("transtype", ttype);

  ScrollableList encoding = cp5.addScrollableList(t.getName() + "encoding")
    .setLabel("Final encoding")
      .setType(ScrollableList.LIST)
        .setPosition(10, 490)
          .setSize(180, 100)
            .moveTo(t);

  h.put("encoding", encoding);

  for (int i=0; i<ENCODINGNO; i++) {
    encoding.addItem(encoding_name(i), i);
  }

  encoding.getItem(1).put("state", true);
  encoding.setValue(1);

  return h;
}

void image_switch(int v) {
  switch(v) {
  case 0: 
    current = img;
    break;
  case 1: 
    current = isegm; 
    break;
  case 2: 
    current = ipred; 
    break;
  case 3: 
    current = result; 
    break;
  }
  reset_buffer();
}

void presets(int i) {
  current_preset = (String)presets_list.getItem(i).get("text");
  try {
    println("Loading preset: " + current_preset);
    ObjectInputStream ois = new ObjectInputStream(createInput("presets"+File.separator+current_preset));
    HashMap<String, Object> map = (HashMap)ois.readObject();
    fromHashMap(map);
    ois.close();
  } 
  catch (IOException e) {
    println("Failed to load preset: " + current_preset);
    current_preset = null;
  } 
  catch (ClassNotFoundException e) {
    println("Failed to load preset: " + current_preset);
    current_preset = null;
  }
}

void save_preset() {
  String s = preset_name.getText();
  if (s != null && !s.trim().isEmpty()) {
    try {
      println("Saving preset: " + s);
      ObjectOutputStream oos = new ObjectOutputStream(createOutput("presets"+File.separator+s.toLowerCase()));
      oos.writeObject(toHashMap());
      oos.close();
    } 
    catch (IOException e) {
      println("Failed to save preset: " + s);
    }
  }
  updatePresets();
}

void updatePresets() {
  String[] filenames;
  println("Loading presets");
  java.io.File folder = new java.io.File(sketchPath("presets"));
  filenames = folder.list();
  if (filenames != null) {
    presets_list.clear(); 
    for (String s : sort (filenames)) {
      presets_list.addItem(s, s);
    }
  }
  presets_count = filenames.length;
}

void readValues() {
  ccfg.colorspace = (int)sl_cs.getValue();
  ccfg.color_outside = color(co_r.getValue(), co_g.getValue(), co_b.getValue());

  for (int p=0; p<3; p++) {
    HashMap<String, ControllerInterface> map = separate_channels_toggle ? chmap[p] : chmap[0];

    ccfg.min_block_size[p] = 1<<(int)map.get("min").getValue();
    ccfg.max_block_size[p] = 1<<(int)map.get("max").getValue();
    ccfg.segmentation_precision[p] = map.get("thr").getValue();

    ccfg.prediction_method[p] = (Integer)((ScrollableList)map.get("pred")).getItem((int)map.get("pred").getValue()).get("value");
    ccfg.quantization_value[p] = (int)map.get("quant").getValue();
    ccfg.clamp_method[p] = (int)map.get("clamp").getValue();

    ccfg.transform_type[p] = (int)map.get("transtype").getValue();
    ccfg.transform_method[p] = (Integer)((ScrollableList)map.get("trans")).getItem((int)map.get("trans").getValue()).get("value");
    ccfg.transform_compress[p] = map.get("compress").getValue();
    ccfg.transform_scale[p] = (int)pow(2.0, map.get("scale").getValue());

    ccfg.encoding_method[p] = (Integer)((ScrollableList)map.get("encoding")).getItem((int)map.get("encoding").getValue()).get("value");
  }
}

HashMap<String, Object> toHashMap() {
  HashMap<String, Object> m = new HashMap();

  m.put("colorspace", sl_cs.getValue());
  m.put("color_outside_r", co_r.getValue());
  m.put("color_outside_g", co_g.getValue());
  m.put("color_outside_b", co_b.getValue());
  m.put("separate_channels", separate_channels.getArrayValue());

  for (int p=0; p<3; p++) {
    HashMap<String, ControllerInterface> map = chmap[p];
    String ch = "ch"+p;

    for (String k : map.keySet ()) {
      if (map.get(k) instanceof RadioButton) {
        m.put(ch+k, map.get(k).getArrayValue());
      } else {
        m.put(ch+k, map.get(k).getValue());
      }
    }
  }

  return m;
}

void fromHashMap(HashMap<String, Object> m) {
  sl_cs.setValue((Float)m.get("colorspace"));
  co_r.setValue((Float)m.get("color_outside_r"));
  co_g.setValue((Float)m.get("color_outside_g"));
  co_b.setValue((Float)m.get("color_outside_b"));
  if (m.get("separate_channels") != null)
    separate_channels.setArrayValue((float[])m.get("separate_channels"));
  else
    separate_channels.deactivate(0);

  for (int p=0; p<3; p++) {
    HashMap<String, ControllerInterface> map = chmap[p];
    String ch = "ch"+p;

    for (String k : map.keySet ()) {
      if (map.get(k) instanceof RadioButton) {
        map.get(k).setArrayValue((float[])m.get(ch+k));
      } else {
        map.get(k).setValue((Float)m.get(ch+k));
      }
    }
  }

  toggle_sep_chan();
}

void reload_image() {
  println("Reload image done");
  load_image(origname, false);
  ipred = isegm = null;
  reset_buffer();
}

void keep_image() {
  img = current;
}

String session_prefix() {
  if (do_skip_session) 
    return "";
  else
    return "_" + session_id;
}

void encode_batch(boolean dopresets) {
  println("batch: "+foldername);
  java.io.File folder = new java.io.File(dataPath(foldername)); // set up a File object for the directory
  filenames = folder.list(extfilter); // fill the fileNames string array with the filter result
  curFrame = 0;
  String preset_dir = dopresets ? File.separator + current_preset : "";
  while (curFrame<filenames.length) {
    String curr_name = foldername+File.separator+"batch"+session_prefix()+preset_dir+File.separator+filenames[curFrame];
    println("Encoding: " + curr_name);
    img = loadImage(foldername+File.separator+filenames[curFrame]);
    result = encode(img, curr_name.replace(".png", "").replace(".jpg", "").replace(".jpeg", "").replace(".bmp", "")+".glic"); // todo: make filename without extension
    result.save(curr_name);
    current = result;
    reset_buffer();
    curFrame++;
  }
}

void encode_button() {
  readValues();
  if (!isBatch) {
    println("Encoding: " + foldername+File.separator+filename+session_prefix()+File.separator+glic_filename.getText());
    result = encode(img, foldername+File.separator+filename+session_prefix()+File.separator+glic_filename.getText());
    current = result;
    reset_buffer();
  } else {
    encode_batch(false);
  }
  bbar_reset("Result");
}

void decode_button() {
  if (!isBatch) {
    println("Decoding: " + foldername+File.separator+filename+session_prefix()+File.separator+glic_filename.getText());
    result = decode(foldername+File.separator+filename+session_prefix()+File.separator+glic_filename.getText());
    current = result;
    reset_buffer();
  } else {
    println("Batch: "+foldername);
    java.io.File folder = new java.io.File(dataPath(foldername)+File.separator + "batch" + session_prefix()); // set up a File object for the directory
    filenames = folder.list(glicfilter); // fill the fileNames string array with the filter result
    curFrame = 0;
    while (curFrame<filenames.length) {
      String curr_name = foldername+File.separator+"batch"+session_prefix()+File.separator+filenames[curFrame];
      println("Decoding: " + curr_name);
      result = decode(curr_name);
      result.save(curr_name.replace(".glic", "")+".png");
      current = result;
      reset_buffer();
      curFrame++;
    }
  }
  bbar_reset("Result");
}

void save_buffer(String pref) {
  if (buffer != null) {
    String ppref = "".equals(pref) ? "" : (pref + "_");
    String fn = foldername+File.separator+filename+session_prefix()+File.separator+ppref+save_filename.getText();
    println("Saving: " + fn);
    buffer.save(fn);
    save_filename.setText(get_next_filename());
    println("Saved");
  }
}

void save_button() {
  save_buffer("");
}

int filename_cnt = 0;
String get_next_filename() {
  return filename+"_"+nf(filename_cnt++, 6)+".png";
}

void bbar_reset(String h) {
  for (String s : bbar_names) {
    if (h.equals(s)) {
      bbar.changeItem(s, "selected", true);
    } else {
      bbar.changeItem(s, "selected", false);
    }
  }
}

void new_session() {

  if (!do_skip_session) {
    session_id = hex(sdf.format(new Date()).hashCode());
    println("Session name: " + session_id);
  } else {
    session_id = "";
  }
  filename_cnt = 0;
  save_filename.setText(get_next_filename());
  glic_filename.setText(filename+".glic");
}

void load_image(String fname, boolean reset_session) {
  println("Loading file: " + fname);

  if ("jpg".equals(fileext)
    || "jpeg".equals(fileext)
    || "gif".equals(fileext)
    || "png".equals(fileext)
    || "bmp".equals(fileext)) {
    img = loadImage(fname);
    bbar_reset("Image");
  } else {
    result = img = decode(fname);
    bbar_reset("Result");
  }

  if (reset_session) new_session();

  current = img;
  reset_buffer();
}

void fileSelected(File selection) {
  if (selection != null) {
    current = null;

    String fn = selection.getName();
    int i = fn.lastIndexOf('.');
    fileext = fn.substring(i+1).toLowerCase();
    filename = fn.substring(0, i);
    foldername = selection.getParent();

    origname = selection.getAbsolutePath();
    load_image(origname, true);
  }
}

boolean resetting_buffer = false;
void reset_buffer() {
  resetting_buffer = true;
  if (current != null) { 
    float ratio = (float)current.width/(float)current.height;
    neww = ratio < 1.0 ? (int)(max_display_size * ratio) : max_display_size;
    newh = ratio < 1.0 ? max_display_size : (int)(max_display_size / ratio);
    posx = ratio < 1.0 ? (max_display_size-neww) / 2 : 0;
    posy = ratio < 1.0 ? 0 : (max_display_size-newh) / 2;
    buffer = createGraphics(current.width, current.height);
    buffer.beginDraw();
    buffer.image(current, 0, 0);
    buffer.endDraw();
  }
  resetting_buffer = false;
}

void load_button() {
  selectInput("Select a file to process:", "fileSelected");
}

void toggle_sep_chan() {
  if (separate_channels.getArrayValue()[0]==1) {
    ch1.setLabel("Channel 1");
    ch2.setVisible(true);
    ch3.setVisible(true);
    separate_channels_toggle = true;
  } else {
    ch1.setLabel("All channels");
    ch2.setVisible(false);
    ch3.setVisible(false);
    separate_channels_toggle = false;
  }
}

void controlEvent(ControlEvent e) {
  if (e.isFrom(separate_channels)) {
    toggle_sep_chan();
  }

  if (e.isFrom(batch)) {
    isBatch = !isBatch;
  }

  if (e.isFrom(skip_header)) {
    do_skip_header = !do_skip_header;
  }

  if (e.isFrom(skip_session)) {
    do_skip_session = !do_skip_session;
    new_session();
  }

  if (e.isFrom(ch1mn)) {
    float mn = ch1mn.getValue();
    float mx = ch1mx.getValue();
    if (mn>mx) ch1mx.setValue(mn);
  }
  if (e.isFrom(ch2mn)) {
    float mn = ch2mn.getValue();
    float mx = ch2mx.getValue();
    if (mn>mx) ch2mx.setValue(mn);
  }
  if (e.isFrom(ch3mn)) {
    float mn = ch3mn.getValue();
    float mx = ch3mx.getValue();
    if (mn>mx) ch3mx.setValue(mn);
  }

  if (e.isFrom(ch1mx)) {
    float mn = ch1mn.getValue();
    float mx = ch1mx.getValue();
    if (mx<mn) ch1mn.setValue(mx);
  }
  if (e.isFrom(ch2mx)) {
    float mn = ch2mn.getValue();
    float mx = ch2mx.getValue();
    if (mx<mn) ch2mn.setValue(mx);
  }
  if (e.isFrom(ch3mx)) {
    float mn = ch3mn.getValue();
    float mx = ch3mx.getValue();
    if (mx<mn) ch3mn.setValue(mx);
  }
}

