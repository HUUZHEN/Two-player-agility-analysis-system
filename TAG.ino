#include <Arduino.h>
#include <WiFi.h>
#include <WiFiUdp.h>

// WiFi 設定
const char* ssid = "usb_lab_2.4G";        // 替換為你的 WiFi 名稱
const char* password = "usblabwifi"; // 替換為你的 WiFi 密碼

// UDP 設定
WiFiUDP udp;
const char* udp_address = "192.168.1.28";  // 替換為你電腦的 IP 地址
const int udp_port = 4210;

// UWB 模組設置
String DATA = "";
int UWB_MODE = 0;  // 0: Tag mode
int UWB_T_NUMBER = 0;

// Anchor 座標（單位：公尺）
float anchor_coords[3][2] = {
  {0.0, 0.0},    // Anchor 0
  {2.0, 0.0},    // Anchor 1
  {1.0, 1.732}   // Anchor 2
};

// Tag 座標
float tag_x = 0.0, tag_y = 0.0;

// 平滑濾波
float smoothed_distances[3] = {0.0, 0.0, 0.0};
void smooth_distances(float new_dist[3]) {
  for (int i = 0; i < 3; i++) {
    smoothed_distances[i] = 0.3 * smoothed_distances[i] + 0.7 * new_dist[i];
  }
}

// 三角定位函數
void calculate_tag_position(float d0, float d1, float d2) {
  float x1 = anchor_coords[1][0], y1 = anchor_coords[1][1];
  float x2 = anchor_coords[2][0], y2 = anchor_coords[2][1];

  tag_x = (d0 * d0 - d1 * d1 + x1 * x1) / (2 * x1);
  tag_y = (d0 * d0 - d2 * d2 + x2 * x2 + y2 * y2) / (2 * y2) - (x2 / y2) * tag_x;

  // 邊界檢查
  if (isnan(tag_x) || isnan(tag_y) || tag_x < -0.5 || tag_x > 2.5 || tag_y < -0.5 || tag_y > 2.5) {
    tag_x = 1.0;  // 預設位置
    tag_y = 1.0;
  }
}

// WiFi 連接函數
void setup_wifi() {
  WiFi.begin(ssid, password);
  Serial.print("連接 WiFi");
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.println("WiFi 連接成功!");
    Serial.print("IP 地址: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println();
    Serial.println("WiFi 連接失敗!");
  }
}

// 發送 UDP 數據
void send_udp_data() {
  if (WiFi.status() == WL_CONNECTED) {
    udp.beginPacket(udp_address, udp_port);
    
    // 構建 JSON 數據
    String json_data = "{\"tag_x\":";
    json_data += String(tag_x, 2);
    json_data += ",\"tag_y\":";
    json_data += String(tag_y, 2);
    json_data += ",\"distances\":[";
    json_data += String(smoothed_distances[0], 2) + ",";
    json_data += String(smoothed_distances[1], 2) + ",";
    json_data += String(smoothed_distances[2], 2);
    json_data += "]}";
    
    udp.print(json_data);
    udp.endPacket();
    
    Serial.println("發送: " + json_data);
  } else {
    Serial.println("WiFi 未連接，無法發送數據");
  }
}

// 讀取 UWB 數據
void UWB_readString() {
  if (Serial2.available()) {
    DATA = "";
    unsigned long start_time = millis();
    while (millis() - start_time < 100) {
      if (Serial2.available()) {
        DATA += Serial2.readStringUntil('\n');
      }
    }

    Serial.println("UWB 原始數據: " + DATA);

    // 解析距離數據
    float distances[3];
    bool valid_data = true;
    UWB_T_NUMBER = 0;
    
    for (int i = 0; i < 3; i++) {
      String anchor_id = "an" + String(i) + ":";
      int start_idx = DATA.indexOf(anchor_id);
      if (start_idx != -1) {
        int end_idx = DATA.indexOf("m", start_idx);
        if (end_idx != -1) {
          String dist_str = DATA.substring(start_idx + 4, end_idx);
          distances[i] = dist_str.toFloat();
          if (distances[i] <= 0 || distances[i] > 5) {
            valid_data = false;
          }
          UWB_T_NUMBER++;
        } else {
          valid_data = false;
        }
      } else {
        valid_data = false;
      }
    }

    if (valid_data && UWB_T_NUMBER >= 3) {
      smooth_distances(distances);
      calculate_tag_position(smoothed_distances[0], smoothed_distances[1], smoothed_distances[2]);
      
      // 通過 WiFi 發送數據到電腦
      send_udp_data();
    } else {
      Serial.println("數據無效，跳過");
      // 即使數據無效也發送一個錯誤信息（用於測試）
      if (WiFi.status() == WL_CONNECTED) {
        udp.beginPacket(udp_address, udp_port);
        udp.print("{\"error\":\"Invalid UWB data\"}");
        udp.endPacket();
      }
    }
  }
}

// 設置 UWB 模組
void UWB_setupmode() {
  Serial.println("設置 UWB 模組為 Tag 模式...");
  for (int b = 0; b < 2; b++) {
    delay(50);
    Serial2.println("AT+anchor_tag=0\r\n");
    delay(50);
    Serial2.println("AT+interval=1\r\n");
    delay(50);
    Serial2.println("AT+switchdis=1\r\n");
    delay(50);
    if (b == 0) {
      Serial2.println("AT+RST\r\n");
      delay(1000);  // 等待重啟
    }
  }
  Serial.println("UWB 設置完成");
}

// 測試函數：發送假數據（用於測試連接）
void send_test_data() {
  static float test_x = 1.0;
  static float test_y = 1.0;
  static float direction_x = 0.1;
  static float direction_y = 0.05;
  
  // 模擬移動
  test_x += direction_x;
  test_y += direction_y;
  
  // 邊界反彈
  if (test_x > 2.0 || test_x < 0.0) direction_x = -direction_x;
  if (test_y > 1.8 || test_y < 0.0) direction_y = -direction_y;
  
  if (WiFi.status() == WL_CONNECTED) {
    udp.beginPacket(udp_address, udp_port);
    String test_json = "{\"tag_x\":" + String(test_x, 2) + 
                      ",\"tag_y\":" + String(test_y, 2) + 
                      ",\"distances\":[" + String(test_x + 0.5, 2) + "," + 
                      String(test_y + 0.3, 2) + "," + String(test_x + test_y, 2) + "]}";
    udp.print(test_json);
    udp.endPacket();
    Serial.println("測試數據: " + test_json);
  }
}

void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, 16, 17);
  
  Serial.println("UWB Tag 系統啟動");
  
  // 連接 WiFi
  setup_wifi();
  
  // 設置 UWB
  if (WiFi.status() == WL_CONNECTED) {
    UWB_setupmode();
  }
  
  Serial.println("系統初始化完成");
}

void loop() {
  // 檢查 WiFi 連接
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi 斷線，嘗試重連...");
    setup_wifi();
    delay(5000);
    return;
  }
  
  // 讀取 UWB 數據
  UWB_readString();
  
  // 如果沒有 UWB 數據，每 5 秒發送一次測試數據
  static unsigned long last_test = 0;
  if (millis() - last_test > 5000) {  // 每 5 秒
    Serial.println("發送測試數據...");
    send_test_data();
    last_test = millis();
  }
  
  delay(100);
}