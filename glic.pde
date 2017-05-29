// GLIC - GLitch Image Codec, ready for databending

//////////////////// Config

// batch stuff
import java.util.ArrayList.*;
import java.io.*;
import java.io.File;
int curFrame=0;
boolean isBatch = false;
String filenames[];
java.io.FilenameFilter extfilter = new java.io.FilenameFilter() {
  boolean accept(File dir, String name) {
    if (name.toLowerCase().endsWith("png") || name.toLowerCase().endsWith("jpeg")
      || name.toLowerCase().endsWith("jpg") || name.toLowerCase().endsWith("bmp")) return true;
    else return false;
  }
}; 
java.io.FilenameFilter glicfilter = new java.io.FilenameFilter() {
  boolean accept(File dir, String name) {
    if (name.toLowerCase().endsWith("glic")) return true;
    else return false;
  }
}; 


String filename;
String fileext;
String foldername = "."+File.separator;
String session_id;

////// size of windows
final static int max_display_size = 750;

//////
PImage orig, img, result, isegm, ipred;

PImage current;
int neww, newh, posx=0, posy=0;
PGraphics buffer;

void setup() {
  size(750,750);
  smooth(8);
  frameRate(20);
  
//  img = loadImage("face.jpg");
//  
//  buffer=createGraphics(img.width,img.height);
//  neww=img.width;
//  newh=img.height;
//  result = encode(img,"faa.glic");
//  current = result;
  
  gui();
  
  println("Press TAB to hide/show GUI");
  println("Press SPACE to save image");
  println("");
}

void draw() {
  background(0);
  if (current != null) {
    buffer.beginDraw();
    buffer.image(current, 0, 0);
    buffer.endDraw();
    image(buffer, posx, posy, neww, newh);
  }
}

void keyPressed() {
  if(keyCode == TAB) {
    if(cp5.isVisible()) {
      cp5.hide();
    } else {
      cp5.show();
    }
  }
  //} else if(key == 32) {
  //  save_button();
  //} else if(key == 'l') {
  //  load_button();
  //} else if(key == 'd') {
  //  decode_button();
  //} else if(key == 'e') {
  //  encode_button();
  //}
}
