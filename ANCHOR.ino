#include <Arduino.h>

#define RXD2 16
#define TXD2 17

#define ANCHOR_ID 2  // 請改成 0、1、2 對應三顆 Anchor

// 傳送指令並檢查回應（等待最大 500ms）
bool sendCommandAndCheckResponse(String command, String expected) {
  Serial2.print(command + "\r\n");

  unsigned long startTime = millis();
  String response = "";

  while (millis() - startTime < 500) {
    while (Serial2.available()) {
      response += (char)Serial2.read();
    }
    if (response.indexOf(expected) >= 0) break;
  }

  response.trim();
  Serial.printf("收到回應: %s\n", response.c_str());

  if (response.indexOf(expected) >= 0) {
    Serial.printf("✅ 指令成功: %s\n", command.c_str());
    return true;
  } else {
    Serial.printf("❌ 指令失敗: %s\n", command.c_str());
    return false;
  }
}

void setup() {
  Serial.begin(115200);                  // 調試用序列埠
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2); // 與 UWB 模組通訊

  delay(2000);  // 等待模組上電與啟動完成

  Serial.println("🔧 初始化 UWB Anchor 模組");

  if (!sendCommandAndCheckResponse("AT", "OK")) {
    Serial.println("初始化失敗：無法連接模組");
    while (true) delay(1000);
  }

  if (!sendCommandAndCheckResponse("AT+version?", "AIT-BU01")) {
    Serial.println("初始化失敗：版本確認錯誤");
    while (true) delay(1000);
  }

  // 設定為 Anchor 模式，ANCHOR_ID 需為 0、1、2
  String modeCmd = "AT+anchor_tag=1," + String(ANCHOR_ID);
  if (!sendCommandAndCheckResponse(modeCmd, "OK")) {
    Serial.println("初始化失敗：設定 Anchor 模式錯誤");
    while (true) delay(1000);
  }

  // 設定定位傳送間隔 (單位: ms)
  if (!sendCommandAndCheckResponse("AT+interval=5", "OK")) {
    Serial.println("初始化失敗：設定間隔錯誤");
    while (true) delay(1000);
  }

  Serial.println("✅ Anchor 初始化完成！");
}

void loop() {
  // Anchor 無需主動工作，放空循環
  delay(1000);
}
