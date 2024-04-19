#include <math.h>
#include <LiquidCrystal.h>
// Constants
const float const_g = 6.81; // Acceleration due to gravity
const float const_L1 = 10;  // Length of first pendulum
const float const_L2 = 10;  // Length of second pendulum
const float const_m1 = 1;   // Mass of first pendulum
const float const_m2 = 1;   // Mass of second pendulum
const float const_dt = 0.05; // Time step

// Initial conditions
const float const_theta1 = PI / 2.0; // Initial angle of first pendulum
const float const_theta2 = PI / 2.0; // Initial angle of second pendulum
const float const_omega1 = 2.33;        // Initial angular velocity of first pendulum
const float const_omega2 = 1.97;        // Initial angular velocity of second pendulum


float g = 6.81; // Acceleration due to gravity
float L1 = 10;  // Length of first pendulum
float L2 = 10;  // Length of second pendulum
float m1 = 1;   // Mass of first pendulum
float m2 = 1;   // Mass of second pendulum
float dt = 0.05; // Time step

// Initial conditions
float theta1 = PI / 2.0; // Initial angle of first pendulum
float theta2 = PI / 2.0; // Initial angle of second pendulum
float omega1 = 2.33;        // Initial angular velocity of first pendulum
float omega2 = 1.97;        // Initial angular velocity of second pendulum
// Position
float x1 = 0;
float x2 = 0;
float y1 = 0;
float y2 = 0;
int pRNG = 0;

// LCD
const int rs = 2,
    en = 3,
    d4 = 4,
    d5 = 5,
    d6 = 6,
    d7 = 7;
const int ledPin = 13; //Define LED pin
LiquidCrystal lcd(rs,en,d4,d5,d6,d7);

//UART
float receivedFloat1;
float receivedFloat2;
float receivedFloat3;
float receivedFloat4;

void setup() {
  Serial.begin(9600);
  Serial.setTimeout(250);
  lcd.begin(16,2);
  pinMode(ledPin, OUTPUT);
  lcd.print("Gooood Morning");
  // Initialize Arduino
  // Setup any peripherals
}

void loop() {
  //UART input to modify seed
  
  if (Serial.available() >= 8) { // Check if at least 8 bytes are available to read
    // Read the incoming bytes
    byte buffer[8];
    Serial.readBytes(buffer, 8);

    // Interpret the bytes as separate floating-point numbers
    receivedFloat1 = extractFloat(buffer[0], buffer[1]);
    receivedFloat2 = extractFloat(buffer[2], buffer[3]);
    receivedFloat3 = extractFloat(buffer[4], buffer[5]);
    receivedFloat4 = extractFloat(buffer[6], buffer[7]);
    // You can continue this for more floating-point numbers if needed

    // Print the received numbers to the serial monitor
    Serial.print("Received Float 1: ");
    Serial.println(receivedFloat1, 2); // Print with 2 decimal places
    Serial.print("Received Float 2: ");
    Serial.println(receivedFloat2, 2); // Print with 2 decimal places
    Serial.print("Received Float 3 ");
    Serial.println(receivedFloat3, 2); // Print with 2 decimal places
    Serial.print("Received Float 4: ");
    Serial.println(receivedFloat4, 2); // Print with 2 decimal places
    // You can continue this for more floating-point numbers if needed

    //reset pRNG
    g = const_g;
    m1 = const_m1;
    m2 = const_m2;
    L1 = const_L1;
    L2 = const_L2;
    dt = const_dt;
    theta1 = const_theta1;
    theta2 = const_theta2;
    omega1 = const_omega1;
    omega2 = const_omega2;
  }

  if(receivedFloat1 > 1)
    {m1 = receivedFloat1;}
  if(receivedFloat2 > 1)
    {m2 = receivedFloat2;}
  if(receivedFloat3 > 1)
    {L1 = receivedFloat3;}
  if(receivedFloat4 > 1)
    {L2 = receivedFloat4;}
  int dec1 = (int)(m1 * 100) % 100; 
  int dec2 = (int)(m2 * 100) % 100; 
  int dec3 = (int)(L1 * 100) % 100; 
  int dec4 = (int)(L2 * 100) % 100;
  int seed1 = int(dec1) * 100 + int(dec2);
  int seed2 = int(dec3) * 100 + int(dec4);
  // m1 = receivedFloat1;
  // m2 = receivedFloat2;
  // L1 = receivedFloat3;
  // L2 = receivedFloat4;

  // Calculate new angles and velocities using physics equations
  float alpha1 = (-g * (2 * m1 + m2) * sin(theta1) - m2 * g * sin(theta1 - 2 * theta2) - 2 * sin(theta1 - theta2) * m2 * (omega2 * omega2 * L2 + omega1 * omega1 * L1 * cos(theta1 - theta2))) / (L1 * (2 * m1 + m2 - m2 * cos(2 * theta1 - 2 * theta2)));
  float alpha2 = (2 * sin(theta1 - theta2) * (omega1 * omega1 * L1 * (m1 + m2) + g * (m1 + m2) * cos(theta1) + omega2 * omega2 * L2 * m2 * cos(theta1 - theta2))) / (L2 * (2 * m1 + m2 - m2 * cos(2 * theta1 - 2 * theta2)));

  omega1 += alpha1 * dt;
  omega2 += alpha2 * dt;
  theta1 += omega1 * dt;
  theta2 += omega2 * dt;

  x1 = L1 * sin(theta1);
  y1 = L1 * cos(theta1);

  x2 = L2 * sin(theta2) + x1;
  y2 = L2 * cos(theta2) + y1;

  pRNG = int(x1 * 100) * 1000000 + int(x2 * 100) * 10000 + int(y1 * 100) * 100 + int(y2 * 100);
  // Serial.print("RNG: ");
  // Serial.println(pRNG);
  // Delay for a short time to control the simulation speed
  delay(50);

//Output onto LCD
  lcd.clear(); // Clear the LCD display
  lcd.setCursor(0, 0); // Set cursor to the second row
  lcd.print("A:");
  lcd.print(int(m1)); // Print the received data in decimal format on the LCD
  lcd.setCursor(4, 0); // Set cursor to the second row
  lcd.print("B:");
  lcd.print(int(m2)); // Print the received data in decimal format on the LCD
  lcd.setCursor(8, 0); // Set cursor to the second row
  lcd.print("C:");
  lcd.print(int(L1)); // Print the received data in decimal format on the LCD
  lcd.setCursor(12, 0); // Set cursor to the second row
  lcd.print("D:");
  lcd.print(int(L2)); // Print the received data in decimal format on the LCD

  lcd.setCursor(0, 1); // Set cursor to the second row
  lcd.print("RNG: ");
  lcd.print(pRNG); // Print the received data in decimal format on the LCD

  // Turn on the LED
  digitalWrite(ledPin, HIGH);
  delay(1000); // Keep the LED on for 1 second
  digitalWrite(ledPin, LOW); // Turn off the LED

  Serial.print("Magnetic_Field_Seed:");
  Serial.print(m1);
  Serial.print(", Light_Sensor_Seed:");
  Serial.print(m2);
  Serial.print(", Humidity_Sensory_Seed:");
  Serial.print(L1);
  Serial.print(", Microphone_Seed:");
  Serial.print(L2);
  Serial.print(", pRNG_Value:");
  Serial.println(pRNG);

}

float extractFloat(byte integerPart, byte decimalPart) {
  // Combine the integer and decimal parts into a floating-point number
  float result = float(integerPart) + (float(decimalPart) / 100.0); // Assuming 2 decimal places
  return result;
}