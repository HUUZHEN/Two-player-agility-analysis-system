#include <WiFi.h>
#include <WiFiUdp.h>

#define RXD2 16
#define TXD2 17

// WiFi 設定
const char* ssid = "usb_lab_2.4G";      // <<< 你的 WiFi SSID
const char* password = "usblabwifi";    // <<< 你的 WiFi 密碼

// UDP 設定
const char* udpAddress = "192.168.1.28"; // <<< 電腦 IP
const int udpPort = 4210;

WiFiUDP udp;

// 暫存距離資料
float dist0 = 0, dist1 = 0, dist2 = 0;
bool gotDist0 = false, gotDist1 = false, gotDist2 = false;

// 傳送指令並等待回應
bool sendCommandAndWait(String command, String expectedResponse, int timeout = 2000) {
  Serial.println("🔧 傳送指令: " + command);
  Serial2.print(command + "\r\n");  // 使用 \r\n 結尾
  
  unsigned long startTime = millis();
  String response = "";
  
  while (millis() - startTime < timeout) {
    while (Serial2.available()) {
      char c = Serial2.read();
      if (c >= 32 && c <= 126) {  // 只接受可印字元
        response += c;
      } else if (c == '\n' || c == '\r') {
        response += '\n';
      }
    }
    
    // 檢查是否包含期望的回應
    if (response.indexOf(expectedResponse) >= 0) {
      response.trim();
      Serial.println("✅ 回應: " + response);
      return true;
    }
    delay(10);
  }
  
  response.trim();
  Serial.println("❌ 指令失敗或超時: " + response);
  return false;
}

void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2);

  // 連接 WiFi
  WiFi.begin(ssid, password);
  Serial.print("📶 Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi Connected: " + WiFi.localIP().toString());

  // 按照文檔正確初始化 UWB Tag
  Serial.println("⚙️ 初始化 UWB Tag 模組...");
  
  delay(2000); // 等待模組啟動
  
  // 1. 重置模組
  if (!sendCommandAndWait("AT+RST", "OK")) {
    Serial.println("❌ 重置失敗");
  }
  delay(1000);
  
  // 2. 設定為 Tag 模式 (model=0) - 這個指令會重新初始化模組
  Serial.println("🔧 設定 Tag 模式...");
  Serial2.print("AT+anchor_tag=0\r\n");
  delay(2000);  // 等待重新初始化完成
  
  // 清除所有回應資料
  while (Serial2.available()) {
    Serial.print((char)Serial2.read());
  }
  Serial.println("\n✅ Tag 模式設定完成");
  
  // 3. 設定測距間隔 (5-50)
  if (!sendCommandAndWait("AT+interval=5", "OK")) {
    Serial.println("❌ 設定間隔失敗");
  }
  delay(500);
  
  // 4. 開啟測距功能 (這是關鍵！)
  if (!sendCommandAndWait("AT+switchdis=1", "OK")) {
    Serial.println("❌ 開啟測距失敗");
  }
  delay(500);
  
  // 清除暫存資料
  while (Serial2.available()) Serial2.read();
  Serial.println("✅ UWB Tag 初始化完成！開始接收測距數據...");
}

void loop() {
  static String line = "";

  while (Serial2.available()) {
    char c = Serial2.read();
    if (c == '\n' || c == '\r') {
      if (line.length() > 0) {
        processLine(line);
        line = "";
      }
    } else {
      line += c;
    }
  }
}

void processLine(String line) {
  Serial.println("📥 收到: " + line);

  // 處理實際格式：an0:2.28m, an1:1.72m, an2:1.50m
  if (line.startsWith("an0:")) {
    String distStr = line.substring(4);  // 跳過 "an0:"
    distStr.replace("m", "");           // 移除 "m"
    dist0 = distStr.toFloat();
    gotDist0 = true;
    Serial.printf("🎯 AN0 距離: %.2f\n", dist0);
  } 
  else if (line.startsWith("an1:")) {
    String distStr = line.substring(4);  // 跳過 "an1:"
    distStr.replace("m", "");           // 移除 "m"
    dist1 = distStr.toFloat();
    gotDist1 = true;
    Serial.printf("🎯 AN1 距離: %.2f\n", dist1);
  } 
  else if (line.startsWith("an2:")) {
    String distStr = line.substring(4);  // 跳過 "an2:"
    distStr.replace("m", "");           // 移除 "m"
    dist2 = distStr.toFloat();
    gotDist2 = true;
    Serial.printf("🎯 AN2 距離: %.2f\n", dist2);
    
    // 當收到 AN2 的距離時，檢查是否三個距離都齊全
    if (gotDist0 && gotDist1 && gotDist2) {
      // 計算位置（需要你提供 Anchor 座標）
      float x = calculatePosition_X(dist0, dist1, dist2);
      float y = calculatePosition_Y(dist0, dist1, dist2);
      float z = 0.0;  // 假設在同一平面
      
      Serial.printf("📡 計算位置: X=%.2f, Y=%.2f, Z=%.2f\n", x, y, z);
      
      // 組成 JSON 傳送
      String json = "{";
      json += "\"x\":" + String(x, 2) + ",";
      json += "\"y\":" + String(y, 2) + ",";
      json += "\"z\":" + String(z, 2) + ",";
      json += "\"d0\":" + String(dist0, 2) + ",";
      json += "\"d1\":" + String(dist1, 2) + ",";
      json += "\"d2\":" + String(dist2, 2);
      json += "}";

      // 傳送到 PC
      udp.beginPacket(udpAddress, udpPort);
      udp.print(json);
      udp.endPacket();

      Serial.println("📤 傳送: " + json);

      // 清除旗標，準備下一輪
      gotDist0 = gotDist1 = gotDist2 = false;
    }
  }
}

// 簡單的三邊定位計算函數
// 你需要根據實際 Anchor 座標來修改這些函數
float calculatePosition_X(float d0, float d1, float d2) {
  // 假設 AN0=(0,0), AN1=(5,0), AN2=(2.5,4) 的座標
  // 這只是範例，請替換成你的實際 Anchor 座標
  
  // 使用三邊定位公式
  float x1 = 0, y1 = 0;      // AN0 座標
  float x2 = 5, y2 = 0;      // AN1 座標  
  float x3 = 2.5, y3 = 4;    // AN2 座標
  
  float A = 2*x2 - 2*x1;
  float B = 2*y2 - 2*y1;
  float C = pow(d0,2) - pow(d1,2) - pow(x1,2) + pow(x2,2) - pow(y1,2) + pow(y2,2);
  float D = 2*x3 - 2*x2;
  float E = 2*y3 - 2*y2;
  float F = pow(d1,2) - pow(d2,2) - pow(x2,2) + pow(x3,2) - pow(y2,2) + pow(y3,2);
  
  float x = (C*E - F*B) / (E*A - B*D);
  return x;
}

float calculatePosition_Y(float d0, float d1, float d2) {
  // 同樣的座標假設
  float x1 = 0, y1 = 0;      // AN0 座標
  float x2 = 5, y2 = 0;      // AN1 座標  
  float x3 = 2.5, y3 = 4;    // AN2 座標
  
  float A = 2*x2 - 2*x1;
  float B = 2*y2 - 2*y1;
  float C = pow(d0,2) - pow(d1,2) - pow(x1,2) + pow(x2,2) - pow(y1,2) + pow(y2,2);
  float D = 2*x3 - 2*x2;
  float E = 2*y3 - 2*y2;
  float F = pow(d1,2) - pow(d2,2) - pow(x2,2) + pow(x3,2) - pow(y2,2) + pow(y3,2);
  
  float y = (A*F - D*C) / (A*E - D*B);
  return y;
}
