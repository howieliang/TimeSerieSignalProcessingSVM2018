//*********************************************
// Time-Series Signal Processing and Classification
// e2_CalculateDiff_OneSensor
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
// S for saving the file
// [SPACE] for refreshing the data
// [0-1] Different diff mode

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
}

void draw() {
  background(255);
  
  //Draw the sensor data
  //lineGraph(float[] data, float lowerbound, float upperbound, float x, float y, float width, float height, int _index)
  lineGraph(sensorHist[0], 0, height, 0, 0, width, height, 0); //draw sensor stream
  lineGraph(diffArray[0], -height, height, 0, height*0.5, width, height*0.5, diffMode); //history of signal

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
  if (key == '0') {
    diffMode = 0;
  }
  if (key == '1') {
    diffMode = 1;
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