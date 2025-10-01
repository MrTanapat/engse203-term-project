#!/bin/bash

# ===============================================
# Agent Wallboard API Test Script
# Tests: Login (SP001) and Update Agent Status (AG001)
# ===============================================

# 1. Configuration
API_URL="http://localhost:3001/api"
SP_CODE="SP001"
SP_PASSWORD="password" # สมมติว่ารหัสผ่านคือ 'password'
AGENT_CODE="AG001"

echo "================================================="
echo "🚀 Starting Agent Wallboard API Test"
echo "================================================="

# 2. Login as Supervisor (SP001) to get JWT Token
echo "1. Attempting to login as Supervisor ($SP_CODE)..."

# ใช้ curl เพื่อ Login และใช้ 'jq' ในการแยก Token (ต้องติดตั้ง jq)
# ถ้าไม่มี jq ให้ใช้ grep/sed/awk แทน
LOGIN_RESPONSE=$(curl -s -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d "{ \"agentCode\": \"$SP_CODE\", \"password\": \"$SP_PASSWORD\" }")

# ตรวจสอบว่ามี jq หรือไม่ และแยก Token
if command -v jq &> /dev/null; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
else
    # Fallback: ใช้ grep/awk/sed ในการแยก Token (ไม่แนะนำถ้ามี jq)
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "❌ LOGIN FAILED. Cannot retrieve a valid token. Response:"
    echo "$LOGIN_RESPONSE"
    exit 1
fi

echo "✅ Login successful. Token retrieved."
echo "   Token: $TOKEN (Truncated)" # ไม่ควรแสดง Token เต็มในการใช้งานจริง
echo "-------------------------------------------------"

# 3. Update Agent Status for AG001
NEW_STATUS="Busy"
echo "2. Attempting to update status for Agent $AGENT_CODE to $NEW_STATUS..."

STATUS_RESPONSE=$(curl -s -X PUT "${API_URL}/agents/$AGENT_CODE/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{ \"status\": \"$NEW_STATUS\" }")

# ตรวจสอบว่า Response มีการยืนยันความสำเร็จหรือไม่ (เช่น มี agentCode ใน response)
if echo "$STATUS_RESPONSE" | grep -q "\"agentCode\":\"$AGENT_CODE\"" && echo "$STATUS_RESPONSE" | grep -q "\"newStatus\":\"$NEW_STATUS\""; then
    echo "✅ Status update successful!"
    echo "   Response Snippet: $(echo "$STATUS_RESPONSE" | head -n 1)"
else
    echo "❌ STATUS UPDATE FAILED. Response:"
    echo "$STATUS_RESPONSE"
    exit 1
fi

echo "-------------------------------------------------"
echo "Status check: Attempting to update status to Available (cleanup)..."

# Cleanup/Reset Status (Optional)
curl -s -X PUT "${API_URL}/agents/$AGENT_CODE/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{ "status": "Available" }' > /dev/null

echo "✅ Test script finished successfully."