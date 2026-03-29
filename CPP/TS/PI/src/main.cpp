#include <Arduino.h>

// a1 -> snimac1
// a2 -> snimac2
// pwm5 -> vent
// pwm6 -> spirala

// Pin configuration
constexpr uint8_t PWM_OUT_VENT = 5;
constexpr uint8_t PWM_OUT_SPIR = 6;
constexpr uint8_t ANALOG_IN_1 = A1;
constexpr uint8_t ANALOG_IN_2 = A2;

// Experiment timing
constexpr uint32_t TS_US = 100000UL;           
constexpr float TS_WARNING_S = 0.11f;
constexpr float EXPERIMENT_DURATION_S = 650.0f;

// Experiment state
bool experimentRunning = false;

// Global experiment timing
uint32_t experimentStartUs = 0;
uint32_t lastControlTickUs = 0;

// Cubic polynomial evaluation
float cubic(float x, float a, float b, float c, float d) {
    return a * x * x * x + b * x * x + c * x + d;
}

// Clamp float value into range
float clampFloat(float value, float minValue, float maxValue) {
    if (value < minValue) {
        return minValue;
    }
    if (value > maxValue) {
        return maxValue;
    }
    return value;
}

// Clamp integer value into range
int clampInt(int value, int minValue, int maxValue) {
    if (value < minValue) {
        return minValue;
    }
    if (value > maxValue) {
        return maxValue;
    }
    return value;
}

// Stop all outputs
void stopOutputs() {
    analogWrite(PWM_OUT_VENT, 0);
    analogWrite(PWM_OUT_SPIR, 0);
}

// Start experiment and reset timers
void startExperiment() {
    experimentStartUs = micros();
    lastControlTickUs = experimentStartUs;
    experimentRunning = true;

    Serial.println("t,Ts,snimac1,setpoint_pb,y_pb,u_pb,u,vent");
}

// Handle serial commands
void handleSerialCommands() {
    if (Serial.available() <= 0) {
        return;
    }

    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command == "START") {
        if (!experimentRunning) {
            startExperiment();
        }
    } else if (command == "STOP") {
        experimentRunning = false;
        stopOutputs();
        Serial.println("STOPPED");
    }
}

void setup() {
    pinMode(PWM_OUT_VENT, OUTPUT);
    pinMode(PWM_OUT_SPIR, OUTPUT);
    pinMode(ANALOG_IN_1, INPUT);
    pinMode(ANALOG_IN_2, INPUT);

    Serial.begin(115200);

    stopOutputs();

    delay(300);
    Serial.println("READY");
}

//start param init
float u_pb = 4.0f;
float u_pb_min = -u_pb;
float u_pb_max = 10 - u_pb;
float Kp = 3.58f;
float Ki = 1.84;
float vent = 6.0f;
float u = 0.0f;
float y_pb = 0.0f;
float integrator = 0.0f;
float e = 0.0f;
float setpoint_pb = 0.35f;
float dy = 0.0f;
float du = 0.0f;


// Main loop
void loop() {
    handleSerialCommands();

    if (!experimentRunning) {
        return;
    }

    uint32_t nowUs = micros();
    uint32_t elapsedSinceLastTickUs = nowUs - lastControlTickUs;

    // Secondary loop executes only when real elapsed time reached Ts
    if (elapsedSinceLastTickUs < TS_US) {
        return;
    }

    float timeTickPeriod = static_cast<float>(elapsedSinceLastTickUs) / 1000000.0f;
    float globalTime = static_cast<float>(nowUs - experimentStartUs) / 1000000.0f;

    // Update tick timestamp only when control loop actually runs
    lastControlTickUs = nowUs;

    // Read raw ADC values
    int a1 = analogRead(ANALOG_IN_1);
    int a2 = analogRead(ANALOG_IN_2);

    // Convert ADC -> snimac values using cubic calibration
    float snimac1 = cubic(
        static_cast<float>(a1),
        4.64044633e-10f,
        -8.44254606e-07f,
        1.02946107e-02f,
        5.87859135e-05f
    );

    float snimac2 = cubic(
        static_cast<float>(a2),
        -9.09109415e-10f,
        8.99002333e-07f,
        9.78867803e-03f,
        -9.65193864e-05f
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Secondary control loop area starts here (Here is logic, all before and after inside main loop is 
    //just plumbing)

    if (globalTime < 10 * 60) {
        u = u_pb;
        y_pb = snimac1;
        integrator = 0.0f;
    } else {
        dy = snimac1 - y_pb;
        e = setpoint_pb - dy;

        integrator += e * timeTickPeriod;

        du = Kp * e + Ki * integrator;
        du = clampFloat(du, u_pb_min, u_pb_max);

        u = u_pb + du;
    }

    float spirala = u;
    // Secondary control loop area ends here
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    


    // After experiment duration expires, force control inputs to zero
    bool experimentFinished = false;
    if (globalTime >= EXPERIMENT_DURATION_S) {
        vent = 0.0f;
        spirala = 0.0f;
        experimentFinished = true;
    }

    // Limit control variables to 0..10
    vent = clampFloat(vent, 0.0f, 10.0f);
    spirala = clampFloat(spirala, 0.0f, 10.0f);

    // Convert vent -> PWM5 count using cubic calibration
    float pwm5Float = cubic(
        vent,
        0.05938291f,
        -0.27988543f,
        24.20478979f,
        -0.52522611f
    );

    // Convert spirala -> PWM6 count using cubic calibration
    float pwm6Float = cubic(
        spirala,
        0.08732906f,
        -0.39322033f,
        22.8496962f,
        -0.61564759f
    );

    // Round to nearest integer and clamp to valid PWM range
    int pwm5 = clampInt(static_cast<int>(pwm5Float + 0.5f), 0, 255);
    int pwm6 = clampInt(static_cast<int>(pwm6Float + 0.5f), 0, 255);

    // Output PWM
    analogWrite(PWM_OUT_VENT, pwm5);
    analogWrite(PWM_OUT_SPIR, pwm6);

    // Warning flag for too-large real period
    int warnTs = (timeTickPeriod > TS_WARNING_S) ? 1 : 0;

    // CSV output to Serial
    Serial.print(globalTime, 6);
    Serial.print(",");

    Serial.print(timeTickPeriod, 6);
    Serial.print(",");

    Serial.print(snimac1, 6);
    Serial.print(",");

    Serial.print(setpoint_pb, 6);
    Serial.print(",");

    Serial.print(y_pb, 6);
    Serial.print(",");

    Serial.print(u_pb, 6);
    Serial.print(",");

    Serial.print(u, 6);
    Serial.print(",");

    Serial.println(vent, 6);

    // Finish experiment and return to idle state
    if (experimentFinished) {
        stopOutputs();
        experimentRunning = false;
        Serial.println("DONE");
    }
}