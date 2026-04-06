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
constexpr float EXPERIMENT_DURATION_S = 2200.0f;

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

// Dot product of 1x2 and 2x1
float rowVec2ColVec2Mul(const float c[2], const float x[2]) {
    return c[0] * x[0] + c[1] * x[1];
}

// Dot product of 1x3 and 3x1
float rowVec3ColVec3Mul(const float a[3], const float b[3]) {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
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

    Serial.println("t,r,snimac1,ym,spir,theta1,theta2,theta3,ypb,Ts,vent");
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

constexpr float PI_F = 3.14159265358979323846f;
constexpr float R_PERIOD = 400.0f;
constexpr float R_AMPLITUDE = 0.5f;

float vent = 6.0f;
float spirala = 0.0f;

// MRAC parameters
constexpr float A0M = 1.0f;
constexpr float A1M = 20.0f;
constexpr float B0M = 1.0f;

constexpr float ALPHA1 = 14.0f * 0.01f;
constexpr float ALPHA2 = 30.0f * 0.01f;
constexpr float ALPHA3 = 14.0f * 0.01f;

constexpr float SIGN_B0 = 1.0f;
constexpr float TS = 0.1f;

constexpr float U_pb = 3.0f;
constexpr float T_SETTLE = 400.0f;

constexpr float U_MIN = 0.0f;
constexpr float U_MAX = 10.0f;

// State space matrices
const float A_MRAC[2][2] = {
    {0.0f, 1.0f},
    {-A0M, -A1M}
};

const float B_MRAC[2] = {
    0.0f,
    1.0f
};

const float C_RF[2] = {
    1.0f,
    0.0f
};

const float C_YM[2] = {
    B0M,
    0.0f
};

// MRAC states
float Theta[3] = {0.0f, 0.0f, 0.0f};
float Theta_used[3] = {0.0f, 0.0f, 0.0f};
float Theta_next_arr[3] = {0.0f, 0.0f, 0.0f};

float x_ym[2] = {0.0f, 0.0f};
float x_yf[2] = {0.0f, 0.0f};
float x_rf[2] = {0.0f, 0.0f};

float x_ym_next_arr[2] = {0.0f, 0.0f};
float x_yf_next_arr[2] = {0.0f, 0.0f};
float x_rf_next_arr[2] = {0.0f, 0.0f};

float y_prev = 0.0f;
float y_prev_next = 0.0f;

float y_pb = 0.0f;
float r_pb = 0.0f;
float y_pb_next = 0.0f;
float r_pb_next = 0.0f;

float sw = 0.0f;
float sw_next = 0.0f;

// MRAC signals for logging
float r = 0.0f;
float y = 0.0f;
float ym = 0.0f;
float yf = 0.0f;
float ydot_f = 0.0f;
float rf = 0.0f;
float e = 0.0f;

float dy = 0.0f;
float dr = 0.0f;
float dy_prev = 0.0f;
float dy_dot = 0.0f;

float omega[3] = {0.0f, 0.0f, 0.0f};

float u = U_pb;
float du = 0.0f;
float u_unsat = U_pb;
float dTheta[3] = {0.0f, 0.0f, 0.0f};

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

    // MAIN CONTROL LOGIC //////////////////////////////////////////////////////////////////

    // Measured output
    y = snimac1;

    // Reference generation

    r = R_AMPLITUDE * sinf(2.0f * PI_F * globalTime / R_PERIOD);

    // Default outputs
    u = U_pb;
    ym = 0.0f;

    Theta_used[0] = Theta[0];
    Theta_used[1] = Theta[1];
    Theta_used[2] = Theta[2];

    Theta_next_arr[0] = Theta[0];
    Theta_next_arr[1] = Theta[1];
    Theta_next_arr[2] = Theta[2];

    x_ym_next_arr[0] = x_ym[0];
    x_ym_next_arr[1] = x_ym[1];

    x_yf_next_arr[0] = x_yf[0];
    x_yf_next_arr[1] = x_yf[1];

    x_rf_next_arr[0] = x_rf[0];
    x_rf_next_arr[1] = x_rf[1];

    y_prev_next = y;
    y_pb_next = y_pb;
    r_pb_next = r_pb;
    sw_next = sw;

    // Plant settle
    if (globalTime < T_SETTLE) {
        u = U_pb;
        ym = 0.0f;

        y_prev_next = y;
        y_pb_next = y_pb;
        r_pb_next = r_pb;
        sw_next = sw;
    } else {
        float x_ym_work[2];
        float x_yf_work[2];
        float x_rf_work[2];
        float Theta_work[3];

        // Transition
        if (sw < 0.5f) {
            y_pb_next = y;
            r_pb_next = r;

            x_ym_work[0] = 0.0f;
            x_ym_work[1] = 0.0f;

            x_yf_work[0] = 0.0f;
            x_yf_work[1] = 0.0f;

            x_rf_work[0] = 0.0f;
            x_rf_work[1] = 0.0f;

            Theta_work[0] = Theta[0];
            Theta_work[1] = Theta[1];
            Theta_work[2] = Theta[2];

            dy_prev = 0.0f;
            sw_next = 1.0f;
        } else {
            x_ym_work[0] = x_ym[0];
            x_ym_work[1] = x_ym[1];

            x_yf_work[0] = x_yf[0];
            x_yf_work[1] = x_yf[1];

            x_rf_work[0] = x_rf[0];
            x_rf_work[1] = x_rf[1];

            Theta_work[0] = Theta[0];
            Theta_work[1] = Theta[1];
            Theta_work[2] = Theta[2];

            dy_prev = y_prev - y_pb;
        }

        // Normalize
        dy = y - y_pb_next;
        dr = r - r_pb_next;

        // Derivative
        dy_dot = (dy - dy_prev) / timeTickPeriod;

        // Outputs of dynamic blocks
        ym = rowVec2ColVec2Mul(C_YM, x_ym_work);
        yf = x_yf_work[0];
        ydot_f = x_yf_work[1];
        rf = rowVec2ColVec2Mul(C_RF, x_rf_work);

        // Error
        e = dy - ym;

        // Regressor
        omega[0] = dy;
        omega[1] = dy_dot;
        omega[2] = dr;

        // Control law
        du = rowVec3ColVec3Mul(Theta_work, omega);
        u_unsat = U_pb + du;
        u = clampFloat(u_unsat, U_MIN, U_MAX);

        // Adaptation law
        dTheta[0] = -SIGN_B0 * e * (ALPHA1 * yf);
        dTheta[1] = -SIGN_B0 * e * (ALPHA2 * ydot_f);
        dTheta[2] = -SIGN_B0 * e * (ALPHA3 * rf);

        Theta_next_arr[0] = Theta_work[0] + dTheta[0] * timeTickPeriod;
        Theta_next_arr[1] = Theta_work[1] + dTheta[1] * timeTickPeriod;
        Theta_next_arr[2] = Theta_work[2] + dTheta[2] * timeTickPeriod;

        Theta_used[0] = Theta_work[0];
        Theta_used[1] = Theta_work[1];
        Theta_used[2] = Theta_work[2];

        // State updates
        float Ax[2];
        float bu[2];

        mat2x2Vec2Mul(A_MRAC, x_ym_work, Ax);
        bu[0] = B_MRAC[0] * dr;
        bu[1] = B_MRAC[1] * dr;
        x_ym_next_arr[0] = x_ym_work[0] + timeTickPeriod * (Ax[0] + bu[0]);
        x_ym_next_arr[1] = x_ym_work[1] + timeTickPeriod * (Ax[1] + bu[1]);

        mat2x2Vec2Mul(A_MRAC, x_yf_work, Ax);
        bu[0] = B_MRAC[0] * dy;
        bu[1] = B_MRAC[1] * dy;
        x_yf_next_arr[0] = x_yf_work[0] + timeTickPeriod * (Ax[0] + bu[0]);
        x_yf_next_arr[1] = x_yf_work[1] + timeTickPeriod * (Ax[1] + bu[1]);

        mat2x2Vec2Mul(A_MRAC, x_rf_work, Ax);
        bu[0] = B_MRAC[0] * dr;
        bu[1] = B_MRAC[1] * dr;
        x_rf_next_arr[0] = x_rf_work[0] + timeTickPeriod * (Ax[0] + bu[0]);
        x_rf_next_arr[1] = x_rf_work[1] + timeTickPeriod * (Ax[1] + bu[1]);

        y_prev_next = y;
    }

    // Commit next states after MRAC step
    Theta[0] = Theta_next_arr[0];
    Theta[1] = Theta_next_arr[1];
    Theta[2] = Theta_next_arr[2];

    x_ym[0] = x_ym_next_arr[0];
    x_ym[1] = x_ym_next_arr[1];

    x_yf[0] = x_yf_next_arr[0];
    x_yf[1] = x_yf_next_arr[1];

    x_rf[0] = x_rf_next_arr[0];
    x_rf[1] = x_rf_next_arr[1];

    y_prev = y_prev_next;
    y_pb = y_pb_next;
    r_pb = r_pb_next;
    sw = sw_next;

    // Final output
    spirala = u;
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

    Serial.print(r, 6);
    Serial.print(",");

    Serial.print(y, 6);
    Serial.print(",");

    Serial.print(ym, 6);
    Serial.print(",");

    Serial.print(u, 6);
    Serial.print(",");

    Serial.print(Theta[0], 6);
    Serial.print(",");

    Serial.print(Theta[1], 6);
    Serial.print(",");

    Serial.print(Theta[2], 6);
    Serial.print(",");

    Serial.print(y_pb, 6);
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