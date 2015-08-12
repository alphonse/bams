// -------------------------------------------------------------------------
// bams: Bicycle-based Air Monitoring System
// v. 1.0 | AF | 2015-08-11
// -------------------------------------------------------------------------
// Contains code for Adafruit GPS modules using MTK3329/MTK3339 driver
// and reads data from GPS, MQ-135 VOC sensor, and Shinyei PPD42 dust sensor
// -------------------------------------------------------------------------

#include <SPI.h>
#include <Adafruit_GPS.h>
#include <SoftwareSerial.h>
#include <SD.h>
#include <avr/sleep.h>

SoftwareSerial mySerial(8, 7);
Adafruit_GPS GPS(&mySerial);

#define GPSECHO  true
#define chipSelect 10
#define ledPin 13

File logfile;
char filename[15];
unsigned long INTERVAL = 1000;
unsigned long acc = 0.0;
float raw = 0.0;
float filtered = 1.0;
float ALPHA = 0.9;
float voc;

// this keeps track of whether we're using the interrupt
// off by default!
boolean usingInterrupt = false;
void useInterrupt(boolean); // Func prototype keeps Arduino 0023 happy

// read a Hex value and return the decimal equivalent
uint8_t parseHex(char c) {
  if (c < '0')
    return 0;
  if (c <= '9')
    return c - '0';
  if (c < 'A')
    return 0;
  if (c <= 'F')
    return (c - 'A')+10;
}

// blink out an error code
void error(uint8_t errno) {
  /*
  if (SD.errorCode()) {
   putstring("SD error: ");
   Serial.print(card.errorCode(), HEX);
   Serial.print(',');
   Serial.println(card.errorData(), HEX);
   }
   */
  while(1) {
    uint8_t i;
    for (i=0; i<errno; i++) {
      digitalWrite(ledPin, HIGH);
      delay(100);
      digitalWrite(ledPin, LOW);
      delay(100);
    }
    for (i=errno; i<10; i++) {
      delay(200);
    }
  }
}

void setup()  
{
  pinMode(9, INPUT); // Shinyei on Pin 9
  Serial.begin(115200);

  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
    error(2);
  }

  strcpy(filename, "GPSLOG00.TXT");
  for (uint8_t i = 0; i < 100; i++) {
    filename[6] = '0' + i/10;
    filename[7] = '0' + i%10;
    // create if does not exist, do not open existing, write, sync after write
    if (! SD.exists(filename)) {
      break;
    }
  }

  logfile = SD.open(filename, FILE_WRITE);
  if( ! logfile ) {
    Serial.print("Couldnt create "); 
    Serial.println(filename);
    error(3);
  }
  logfile.println("time, lat, lon, speed, angle, alt, satellites, pm_raw, pm_filt, voc");
  logfile.close();
  Serial.print("Writing to "); 
  Serial.println(filename);

  GPS.begin(9600);
  GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA);  
  // Set the update rate
  GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ);

  useInterrupt(true);

  delay(1000);
  // Ask for firmware version
  mySerial.println(PMTK_Q_RELEASE);
}


// Interrupt is called once a millisecond, looks for any new GPS data, and stores it
SIGNAL(TIMER0_COMPA_vect) {
  char c = GPS.read();
  // if you want to debug, this is a good time to do it!
#ifdef UDR0
  if (GPSECHO)
    if (c) UDR0 = c;  
    // writing direct to UDR0 is much much faster than Serial.print 
    // but only one character can be written at a time. 
#endif
}

void useInterrupt(boolean v) {
  if (v) {
    // Timer0 is already used for millis() - we'll just interrupt somewhere
    // in the middle and call the "Compare A" function above
    OCR0A = 0xAF;
    TIMSK0 |= _BV(OCIE0A);
    usingInterrupt = true;
  } else {
    // do not call the interrupt function COMPA anymore
    TIMSK0 &= ~_BV(OCIE0A);
    usingInterrupt = false;
  }
}

uint32_t timer = millis();
void loop()                     // run over and over again
{
  acc += pulseIn(9, LOW); // Shinyei on Pin 9 

  // if a sentence is received, we can check the checksum, parse it...
  if (GPS.newNMEAreceived()) {
  
  if (!GPS.parse(GPS.lastNMEA()))   // this also sets the newNMEAreceived() flag to false
    return;  // we can fail to parse a sentence in which case we should just wait for another
  }

  // if millis() or timer wraps around, we'll just reset it
  if (timer > millis())  timer = millis();

  // approximately every 2 seconds or so, print out the current stats
  if (millis() - timer > INTERVAL) {
       
    raw = acc / (timer * 10.0); // Shinyei reading expressed as percentage
    if (isnan(raw) || isinf(raw)) raw = 0.0;  // nan creates propagating error
    filtered = ALPHA * filtered + (1 - ALPHA) * raw; // smooth data
    
    voc = analogRead(A0) * (5000.0 / 1023.0); // get VOC sensor reading
    
    timer = millis(); // reset the timer
    
    File logfile = SD.open(filename, FILE_WRITE);
    if (logfile) {
    logfile.print("20");
    logfile.print(GPS.year, DEC); logfile.print("-");
    logfile.print(GPS.month, DEC); logfile.print("-");
    logfile.print(GPS.day, DEC); logfile.print(" ");
    logfile.print(GPS.hour, DEC); logfile.print(":");
    logfile.print(GPS.minute, DEC); logfile.print(':');
    logfile.print(GPS.seconds, DEC); logfile.print(", ");
    if (GPS.fix) {
      logfile.print(GPS.latitudeDegrees, 4);
      logfile.print(", "); 
      logfile.print(GPS.longitudeDegrees, 4); logfile.print(", ");
      logfile.print(GPS.speed); logfile.print(", ");
      logfile.print(GPS.angle); logfile.print(", ");
      logfile.print(GPS.altitude); logfile.print(", ");
      logfile.print((int)GPS.satellites); logfile.print(", ");
    }
    logfile.print(raw, 4); logfile.print(", "); logfile.print(filtered, 4); logfile.print(", "); 
    logfile.println(voc);
    logfile.close();
    }
    acc = 0;
  }
}
