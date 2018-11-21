//*********************************************
// Time-Series Signal Processing and Classification
// e5_Statistics_Arduino_OneSensor
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
// The papaya library is included in the /code folder.
// Papaya: A Statistics Library for Processing.Org
// http://adilapapaya.com/papayastatistics/
// Before use, please make sure your Arduino has 1 sensor connected
// to the analog input, and SerialString_OneSensors.ino was uploaded. 
// [SPACE] Pause Data Stream
// [A] Increase the Activation Threshold by 10
// [Z] Decrease the Activation Threshold by 10

import processing.serial.*;
Serial port; 

int[] rawData;
int sensorNum = 1; 
int dataNum = 500;

Table csvData;
String fileName = "data/testData.csv";
boolean b_saveCSV = false;

int label = 0;

float[][] sensorHist = new float[sensorNum][dataNum]; //history data to show
float[][] diffArray = new float[sensorNum][dataNum]; //diff calculation: substract
int diffMode = 0; //0: normal diff; 1: absolute diff
float[] modeArray = new float[dataNum]; //To show activated or not
int activationThld = 20; //The diff threshold of activiation
int windowSize = 50; //The size of data window
float[][] windowArray = new float[sensorNum][windowSize]; //data window collection
boolean b_sampling = false; //flag to keep data collection non-preemptive
int sampleCnt = 0; //counter of samples

//Statistical Features
float[] windowM = new float[sensorNum]; //mean
float[] windowSD = new float[sensorNum]; //standard deviation

boolean b_pause = false; //flag to pause data collection

void setup() {
  size(500, 500);

  //Initiate the dataList and set the header of table
  csvData = new Table();
  csvData.addColumn("x");
  //add more columns here

  //Initiate the serial port
  rawData = new int[sensorNum];
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];//MAC: check the printed list
  //String portName = Serial.list()[9];//WINDOWS: check the printed list
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer

  for (int i = 0; i < modeArray.length; i++) { //Initialize all modes as null
    modeArray[i] = -1;
  }
}

void draw() {
  background(255);

  //Draw the sensor data
  //lineGraph(float[] data, float lowerbound, float upperbound, float x, float y, float width, float height, int _index)
  lineGraph(sensorHist[0], 0, height, 0, 0, width, height*0.3, 0); //history of signal
  lineGraph(diffArray[0], -height, height, 0, height*0.3, width, height*0.3, 0); //history of diff
  lineGraph(windowArray[0], 0, height, 0, height*0.6, width, height*0.3, 0); //history of window

  //Draw the modeArray
  //barGraph(float[] data, float lowerbound, float upperbound, float x, float y, float width, float height)
  barGraph(modeArray, -1, 0, 0, height, width, height);

  pushStyle();
  fill(0);
  textSize(24);
  text("Activation Threshold: "+activationThld, 20, 40);
  text("M: "+windowM[0]+", SD: "+windowSD[0], 20, 70);
  popStyle();

  //for (int i = 0; i < csvData.getRowCount(); i++) { 
  //  //read the values from the file
  //  TableRow row = csvData.getRow(i);
  //  float x = row.getFloat("x");
  //  // add more features here if you have

  //  //form a feature array
  //  float[] features = {x}; //form an array of input features

  //  //draw the data on the Canvas: 
  //  //Note: the row index is used as the label instead
  //  drawDataPoint1D(i, features);
  //}

  if (b_saveCSV) {
    //Save the table to the file folder
    saveTable(csvData, fileName); //save table as CSV file
    println("Saved as: ", fileName);

    //reset b_saveCSV;
    b_saveCSV = false;
  }
}

void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  if (inData.charAt(0) == 'A') {  
    rawData[0] = int(trim(inData.substring(1)));
    appendArray(sensorHist[0], map(rawData[0], 0, 1023, 0, height)); //store the data to history (for visualization)
    float diff = sensorHist[0][0] - sensorHist[0][1]; //normal diff
    if (diffMode==1) diff = abs(sensorHist[0][0] - sensorHist[0][1]); //absolute diff
    appendArray(diffArray[0], diff);

    if (diff>activationThld) { //activate when the absolute diff is beyond the activationThld
      appendArray(modeArray, 0);
      if (b_sampling == false) { //if not sampling
        b_sampling = true; //do sampling
        sampleCnt = 0; //reset the counter
        for (int i = 0; i < sensorNum; i++) {
          for (int j = 0; j < windowSize; j++) {
            windowArray[i][j] = 0; //reset the window
          }
        }
      }
    } else { //otherwise, deactivate.
      appendArray(modeArray, -1);
    }

    if (b_sampling == true) {
      appendArray(windowArray[0], rawData[0]); //store the windowed data to history (for visualization)
      ++sampleCnt;
      if (sampleCnt == windowSize) {
        windowM[0] = Descriptive.mean(windowArray[0]); //mean
        windowSD[0] = Descriptive.std(windowArray[0], true); //standard deviation
        b_sampling = false; //stop sampling if the counter is equal to the window size
      }
    }

    if (csvData.getRowCount()<dataNum) { //keep "dataNum" rows of CSV Data
      TableRow newRow = csvData.addRow();
      newRow.setFloat("x", rawData[0]);
    }
    return;
  }
}

void keyPressed() {
  if (key == 'S' || key == 's') {
    b_saveCSV = true;
  }
  if (key == ' ') {
    csvData.clearRows();
  }
  if (key == 'A' || key == 'a') {
    activationThld = min(activationThld+5, 100);
  }
  if (key == 'Z' || key == 'z') {
    activationThld = max(activationThld-5, 10);
  }
}

//Append a value to a float[] array.
float[] appendArray (float[] _array, float _val) {
  float[] array = _array;
  float[] tempArray = new float[_array.length-1];
  arrayCopy(array, tempArray, tempArray.length);
  array[0] = _val;
  arrayCopy(tempArray, 0, array, 1, tempArray.length);
  return array;
}

//Draw a line graph to visualize the sensor stream
void lineGraph(float[] data, float _l, float _u, float _x, float _y, float _w, float _h, int _index) {
  color colors[] = {
    color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0), color(0, 255, 255), 
    color(255, 0, 255), color(0)
  };
  int index = min(max(_index, 0), colors.length);
  pushStyle();
  float delta = _w/data.length;
  beginShape();
  noFill();
  stroke(colors[index]);
  for (float i : data) {
    float h = map(i, _l, _u, 0, _h);
    vertex(_x, _y+h);
    _x = _x + delta;
  }
  endShape();
  popStyle();
}

//Draw a bar graph to visualize the modeArray
void barGraph(float[] data, float _l, float _u, float _x, float _y, float _w, float _h) {
  color colors[] = {
    color(155, 89, 182), color(63, 195, 128), color(214, 69, 65), color(82, 179, 217), color(244, 208, 63), 
    color(242, 121, 53), color(0, 121, 53), color(128, 128, 0), color(52, 0, 128), color(128, 52, 0)
  };
  pushStyle();
  noStroke();
  float delta = _w / data.length;
  for (int p = 0; p < data.length; p++) {
    float i = data[p];
    int cIndex = min((int) i, colors.length-1);
    if (i<0) fill(255, 100);
    else fill(colors[cIndex], 100);
    float h = map(_u, _l, _u, 0, _h);
    rect(_x, _y-h, delta, h);
    _x = _x + delta;
  }
  popStyle();
}

//functions for drawing the data
void drawDataPoint1D(int _i, float[] _features) { 
  float pD = width/dataNum;
  float pX = map(((float)_i+0.5)/(float)dataNum, 0, 1, 0, width);
  float[] pY = new float[_features.length];
  for (int j = 0; j < _features.length; j++) pY[j] = map(_features[j], 0, 1024, 0, height) ; 
  pushStyle();
  for (int j = 0; j < _features.length; j++) {
    noStroke();
    if (j==0)fill(255, 0, 0);
    ellipse(pX, pY[j], pD, pD);
  }
  popStyle();
}