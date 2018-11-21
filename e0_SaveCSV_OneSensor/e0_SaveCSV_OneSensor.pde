//*********************************************
// Time-Series Signal Processing and Classification
// e0_saveCSV_OneSensor
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
// S for saving the file
// [SPACE] for refreshing the data

import processing.serial.*;
Serial port; 

int[] rawData;
int sensorNum = 1; 
int dataNum = 500;

Table csvData;
String fileName = "data/testData.csv";
boolean b_saveCSV = false;

int label = 0;

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

  for (int i = 0; i < csvData.getRowCount(); i++) { 
    //read the values from the file
    TableRow row = csvData.getRow(i);
    float x = row.getFloat("x");
    // add more features here if you have

    //form a feature array
    float[] features = {x}; //form an array of input features

    //draw the data on the Canvas: 
    //Note: the row index is used as the label instead
    drawDataPoint1D(i, features);
  }

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
    if (csvData.getRowCount()<dataNum) { //keep "dataNum" rows of CSV Data
      TableRow newRow = csvData.addRow();
      newRow.setFloat("x", rawData[0]);
    }
    println("CSV Table Row Count:",csvData.getRowCount());
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