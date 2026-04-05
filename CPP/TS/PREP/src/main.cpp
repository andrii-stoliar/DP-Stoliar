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
constexpr float EXPERIMENT_DURATION_S = 801.0f;

// Experiment state
bool experimentRunning = false;

// Global experiment timing
uint32_t experimentStartUs = 0;
uint32_t lastControlTickUs = 0;

// HELPER FUNCTIONS ////////////////////////////////////////////////////////////////

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

// HELPER FUNCTIONS FOR FILTER /////////////////////////////////////////////////////////

// 2x2 matrix times 2x1 vector
void mat2x2Vec2Mul(const float A[2][2], const float x[2], float result[2]) {
    result[0] = A[0][0] * x[0] + A[0][1] * x[1];
    result[1] = A[1][0] * x[0] + A[1][1] * x[1];
}

// 2x1 vector times scalar
void vec2ScalarMul(const float v[2], float scalar, float result[2]) {
    result[0] = v[0] * scalar;
    result[1] = v[1] * scalar;
}

// 2x1 vector plus 2x1 vector
void vec2Add(const float a[2], const float b[2], float result[2]) {
    result[0] = a[0] + b[0];
    result[1] = a[1] + b[1];
}

// Dot product of 1x2 and 2x1
float rowVec2ColVec2Mul(const float c[2], const float x[2]) {
    return c[0] * x[0] + c[1] * x[1];
}

// Shift history left and append new value
void shiftAppend30(float hist[30], float newValue) {
    for (int i = 0; i < 29; ++i) {
        hist[i] = hist[i + 1];
    }
    hist[29] = newValue;
}

// Mean of 30 samples
float mean30(const float hist[30]) {
    float sum = 0.0f;
    for (int i = 0; i < 30; ++i) {
        sum += hist[i];
    }
    return sum / 30.0f;
}

// SERIAL COMMANDS //////////////////////////////////////////////////////////////////////////

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

    Serial.println("t,r_l,r_g,r_gf,snimac1,y_pb,u,u_g,u_l,u_pb,active_g,Ki_l,Kp_l,Ts,vent");
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

// INIT control variables ///////////////////////////////////////////////////////////////

float vent = 6.0f;
float spirala = 0.0f;

// References
float r_g = 0.0f;
float r_l = 0.0f;
float r_g_prev = 0.0f;
float r_gf = 0.0f;

// Controller activity
int active_g = 0;
int active_l = 1;

// Operating point
float y_pb = 0.0f;
float u_pb = 0.0f;

// Controller states
float I_l = 0.0f;
float I_g = 0.0f;

// Filter state
float x_f[2] = {0.0f, 0.0f};

// Filter matrices
const float A_f[2][2] = {
    {0.0f, 1.0f},
    {-0.01f, -0.2f}
};

const float b_f[2] = {0.0f, 1.0f};
const float c_f[2] = {0.01f, 0.0f};

// Histories
float y_hist[30] = {0.0f};
float u_hist[30] = {0.0f};

// Gain scheduling table
const float y_pb_table[3] = {4.4884f, 6.3412f, 7.7441f};
const float u_pb_table[3] = {2.0f, 4.0f, 6.0f};
const float Kp_l_table[3] = {2.77f, 3.58f, 1.83f};
const float Ki_l_table[3] = {1.48f, 1.84f, 2.20f};

// Global PI
const float Kp_g = 4.0f;
const float Ki_g = 0.7f;

// Active local PI gains
float Kp_l = 0.0f;
float Ki_l = 0.0f;

// Errors and control components
float e_l = 0.0f;
float e_g = 0.0f;
float u_l = 0.0f;
float u_g = 0.0f;
float u = 0.0f;

// Settling detection
float lower_bound = 0.0f;
float upper_bound = 0.0f;
int count_ok = 0;


// MAIN CONTROL LOOP ///////////////////////////////////////////////////////////////////////

void loop() {
    handleSerialCommands();

    if (!experimentRunning) {
        return;
    }

    uint32_t nowUs = micros();
    uint32_t elapsedSinceLastTickUs = nowUs - lastControlTickUs;

    // Loop executes only when real elapsed time reached Ts
    if (elapsedSinceLastTickUs < TS_US) {
        return;
    }

    float timeTickPeriod = static_cast<float>(elapsedSinceLastTickUs) / 1000000.0f;
    float globalTime = static_cast<float>(nowUs - experimentStartUs) / 1000000.0f;

    // Update tick timestamp only when control loop actually runs
    lastControlTickUs = nowUs;

    // OUTPUT control variables (vent, spirala) ///////////////////////////////////////////////////

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

    // INPUT processing ///////////////////////////////////////////////////////////////////////////////////////////////

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

    // Reference generation //////////////////////////////////////////////////////////////////

    // Global reference
    if (globalTime < 1.0f) {
        r_g = 0.0f;
    } else if (globalTime < 401.0f) {
        r_g = 6.3412f;
    } else if (globalTime < 801.0f) {
        r_g = 4.4884f;
    } else {
        r_g = 4.4884f;
    }

    // Local reference
    if (globalTime < 201.0f) {
        r_l = 0.0f;
    } else if (globalTime < 301.0f) {
        r_l = -0.35f;
    } else if (globalTime < 601.0f) {
        r_l = 0.0f;
    } else if (globalTime < 701.0f) {
        r_l = 0.41f;
    } else if (globalTime < 801.0f) {
        r_l = 0.0f;
    } else {
        r_l = 0.0f;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Control law area - PI switching logic

    // 1 Detect step change
    if (r_g != r_g_prev) {
        active_g = 1;
    }

    // 2 Filter global reference
    r_gf = rowVec2ColVec2Mul(c_f, x_f);

    float Afx[2];
    float bfr[2];
    float filterSum[2];

    mat2x2Vec2Mul(A_f, x_f, Afx);
    vec2ScalarMul(b_f, r_g, bfr);
    vec2Add(Afx, bfr, filterSum);

    x_f[0] += filterSum[0] * timeTickPeriod;
    x_f[1] += filterSum[1] * timeTickPeriod;

    // 3 Select local points PI params
    float dist_pb = fabs(y_pb_table[0] - y_pb);
    int idx_pb = 0;

    for (int i = 1; i < 3; ++i) {
        float dist_i = fabs(y_pb_table[i] - y_pb);
        if (dist_i < dist_pb) {
            dist_pb = dist_i;
            idx_pb = i;
        }
    }

    Kp_l = Kp_l_table[idx_pb];
    Ki_l = Ki_l_table[idx_pb];

    // 4 Control errors
    e_l = r_l - (snimac1 - y_pb);
    e_g = r_gf - snimac1;

    // 5 Control law
    u_l = (1 - active_g) * (u_pb + Kp_l * e_l + Ki_l * I_l);
    u_g = active_g * (Kp_g * e_g + Ki_g * I_g);

    u = u_l + u_g;
    u = clampFloat(u, 0.0f, 10.0f);

    // 6 Update histories
    shiftAppend30(y_hist, snimac1);
    shiftAppend30(u_hist, u);

    // 7 Settling detection
    lower_bound = r_g - 0.03f * r_g;
    upper_bound = r_g + 0.03f * r_g;

    count_ok = 0;
    for (int i = 0; i < 30; ++i) {
        if (y_hist[i] >= lower_bound && y_hist[i] <= upper_bound) {
            count_ok++;
        }
    }

    // Two-level switching logic
    float y_pb_new = y_pb;
    float u_pb_new = u_pb;
    int active_g_new = active_g;

    if (active_g == 1 && count_ok >= 25) {
        y_pb_new = mean30(y_hist);
        u_pb_new = mean30(u_hist);
        active_g_new = 0;
    }

    active_l = 1 - active_g;

    // 8 Integral states update
    if (active_l == 1) {
        I_l += e_l * timeTickPeriod;
    } else {
        I_l = 0.0f;
    }

    if (active_g == 1) {
        I_g += e_g * timeTickPeriod;
    } else {
        I_g = (u - Kp_g * e_g) / Ki_g;
    }

    // 9 Memory update
    r_g_prev = r_g;
    y_pb = y_pb_new;
    u_pb = u_pb_new;
    active_g = active_g_new;

    // Final output
    spirala = u;
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // End experiment after duration expires ///////////////////////////////////////////////////////////////////////

    // After experiment duration expires, force control inputs to zero
    bool experimentFinished = false;
    if (globalTime >= EXPERIMENT_DURATION_S) {
        vent = 0.0f;
        spirala = 0.0f;
        experimentFinished = true;
    }

    // Warning flag for too-large real period
    int warnTs = (timeTickPeriod > TS_WARNING_S) ? 1 : 0;

    // CSV output to Serial //////////////////////////////////////////////////////////////////

    Serial.print(globalTime, 6);
    Serial.print(",");

    Serial.print(r_l, 6);
    Serial.print(",");

    Serial.print(r_g, 6);
    Serial.print(",");

    Serial.print(r_gf, 6);
    Serial.print(",");

    Serial.print(snimac1, 6);
    Serial.print(",");

    Serial.print(y_pb, 6);
    Serial.print(",");

    Serial.print(u, 6);
    Serial.print(",");

    Serial.print(u_g, 6);
    Serial.print(",");

    Serial.print(u_l, 6);
    Serial.print(",");

    Serial.print(u_pb, 6);
    Serial.print(",");

    Serial.print(active_g);
    Serial.print(",");

    Serial.print(Ki_l, 6);
    Serial.print(",");

    Serial.print(Kp_l, 6);
    Serial.print(",");

    Serial.print(timeTickPeriod, 6);
    Serial.print(",");

    Serial.println(vent, 6);

    // Finish experiment and return to idle state
    if (experimentFinished) {
        stopOutputs();
        experimentRunning = false;
        Serial.println("DONE");
    }
}