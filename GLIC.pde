// GLIC - GLitch Image Codec, ready for databending

//////////////////// Config

// Hidden stuff (not in GUI)

// Press CTRL-Y to encode image with all presets
// Press CTRL-I to iterate [encoding -> keep image...] `iterate_count` times.
int iterate_count = 5;

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
PImage img, result, isegm, ipred;
String origname;

PImage current;
int neww, newh, posx=0, posy=0;
PGraphics buffer;

void setup() {
  size(750, 750);
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

  println();
  println("Press TAB to hide/show GUI");
  println("Press CTRL-L to load image");
  println("Press CTRL-E to encode image");
  println("Press CTRL-D to decode image");
  println("Press CTRL-S to save image");
  println("Press CTRL-Y to apply all presets");
  println();
  println("Presets provided by: Myrto, Saturn Kat, Letsglitchit, Vivi, NoNoNoNoNo, Pandy Chan, GenerateMe, Jay Di, José Irion Neto.");
  println();
}

void draw() {
  background(0);
  if (buffer != null && !resetting_buffer) {
    image(buffer, posx, posy, neww, newh);
  }
}

boolean isCtrlPressed = false;

void keyPressed() {
  if (keyCode == TAB) {
    if (cp5.isVisible()) {
      cp5.hide();
    } else {
      cp5.show();
    }
  } else if (keyCode == CONTROL && isCtrlPressed == false)
    isCtrlPressed = true;
  else if (isCtrlPressed) {    
    if (char(keyCode) == 'S') {
      save_button();
    } else if (char(keyCode) == 'L') {
      load_button();
    } else if (char(keyCode) == 'D') {
      decode_button();
    } else if (char(keyCode) == 'E') {
      encode_button();
    } else if (char(keyCode) == 'I') {
      println("***** ITERATING ENCODING " + iterate_count + " times!");
      println("be patient");
      for (int i=0; i<iterate_count; i++) {
        println("----------> Iteration number: "+i+"/"+iterate_count);
        encode_button();
        keep_image();
      }
    } else if (char(keyCode) == 'Y') {
      if (img != null) {
        for (int i=0; i<presets_count; i++) {
          presets(i);
          if(isBatch) {
            readValues();
            encode_batch(true);
          } else {
            encode_button();
            save_buffer(current_preset);
          }
        }
      }
    }
  }
}

void keyReleased() {
  if (keyCode == CONTROL) isCtrlPressed = false;
}

