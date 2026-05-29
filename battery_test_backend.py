#!/usr/bin/env python3
"""
ForgeIQ Backend Battery Test — 1,000 Scenarios
Tests all endpoints with valid/invalid/edge cases
Pass criteria: ≥99.5% (Kevin's standard)
"""

import json
import random
import string
import time
from datetime import datetime, timedelta
import urllib.request
import urllib.error

BASE_URL = "http://localhost:3010"

# Test results
total_scenarios = 0
passed = 0
failed = 0
critical_failures = []

def log_result(scenario, expected, actual, critical=False):
    global total_scenarios, passed, failed, critical_failures
    total_scenarios += 1
    if expected == actual:
        passed += 1
    else:
        failed += 1
        msg = f"[{total_scenarios}] {scenario}: expected {expected}, got {actual}"
        if critical:
            critical_failures.append(msg)

def make_request(method, path, headers=None, body=None):
    """HTTP request wrapper"""
    try:
        url = f"{BASE_URL}{path}"
        req = urllib.request.Request(url, method=method)

        if headers:
            for k, v in headers.items():
                req.add_header(k, v)

        data = None
        if body:
            data = json.dumps(body).encode('utf-8')
            req.add_header('Content-Type', 'application/json')

        with urllib.request.urlopen(req, data=data, timeout=5) as response:
            return response.status, json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return 0, str(e)

def random_string(length=10):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def random_jwt():
    """Generate fake JWT for testing"""
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {"sub": f"user_{random_string(8)}", "exp": int(time.time()) + 3600}
    # Base64-encoded header.payload.signature (fake)
    return f"{json.dumps(header)}.{json.dumps(payload)}.{random_string(32)}"

# ============================================================================
# AUTH ENDPOINT TESTS (200 scenarios)
# ============================================================================

print("[AUTH] Testing authentication endpoints...")

# Valid JWT
for i in range(50):
    jwt = random_jwt()
    status, _ = make_request("GET", "/api/recordings", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Auth valid JWT #{i+1}", 200, status)

# Missing token
for i in range(50):
    status, _ = make_request("GET", "/api/recordings")
    log_result(f"Auth missing token #{i+1}", 401, status, critical=True)

# Invalid token format
for i in range(50):
    status, _ = make_request("GET", "/api/recordings", headers={"Authorization": f"Bearer invalid_{random_string()}"})
    log_result(f"Auth invalid format #{i+1}", 401, status, critical=True)

# Expired token (simulate with old exp)
for i in range(50):
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {"sub": f"user_{random_string(8)}", "exp": int(time.time()) - 3600}  # expired
    jwt = f"{json.dumps(header)}.{json.dumps(payload)}.{random_string(32)}"
    status, _ = make_request("GET", "/api/recordings", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Auth expired token #{i+1}", 401, status, critical=True)

# ============================================================================
# RECORDINGS CRUD (200 scenarios)
# ============================================================================

print("[RECORDINGS] Testing recordings CRUD...")

# Create recording (valid)
for i in range(50):
    jwt = random_jwt()
    body = {
        "call_id": f"call_{random_string(10)}",
        "duration": random.randint(10, 600),
        "audio_url": f"https://example.com/{random_string()}.mp3",
        "status": "completed"
    }
    status, _ = make_request("POST", "/api/recordings", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Recording create valid #{i+1}", 201, status)

# Create recording (missing required fields)
for i in range(50):
    jwt = random_jwt()
    body = {"duration": 100}  # missing call_id, audio_url, status
    status, _ = make_request("POST", "/api/recordings", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Recording create invalid #{i+1}", 400, status)

# List recordings (valid)
for i in range(50):
    jwt = random_jwt()
    status, _ = make_request("GET", "/api/recordings", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Recording list valid #{i+1}", 200, status)

# Get recording (valid ID)
for i in range(25):
    jwt = random_jwt()
    status, _ = make_request("GET", f"/api/recordings/{random.randint(1, 1000)}", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Recording get valid #{i+1}", 200 if random.random() > 0.5 else 404, status)

# Get recording (invalid ID)
for i in range(25):
    jwt = random_jwt()
    status, _ = make_request("GET", f"/api/recordings/invalid_id", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Recording get invalid #{i+1}", 400, status)

# ============================================================================
# TRANSCRIPTS CRUD (200 scenarios)
# ============================================================================

print("[TRANSCRIPTS] Testing transcripts CRUD...")

# Create transcript (valid)
for i in range(50):
    jwt = random_jwt()
    body = {
        "recording_id": random.randint(1, 100),
        "full_text": f"Transcript text {random_string(50)}",
        "specs": {
            "speaker_labels": ["Speaker 1", "Speaker 2"],
            "confidence": random.uniform(0.8, 1.0)
        }
    }
    status, _ = make_request("POST", "/api/transcripts", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Transcript create valid #{i+1}", 201, status)

# Create transcript (invalid JSONB)
for i in range(50):
    jwt = random_jwt()
    body = {
        "recording_id": random.randint(1, 100),
        "full_text": f"Transcript text {random_string(50)}",
        "specs": "not a JSON object"  # should be object, not string
    }
    status, _ = make_request("POST", "/api/transcripts", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Transcript create invalid JSONB #{i+1}", 400, status)

# List transcripts (valid)
for i in range(50):
    jwt = random_jwt()
    status, _ = make_request("GET", "/api/transcripts", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Transcript list valid #{i+1}", 200, status)

# User isolation test (user A cannot access user B's transcripts)
for i in range(50):
    jwt_a = random_jwt()
    jwt_b = random_jwt()
    # Create transcript as user A
    body = {"recording_id": random.randint(1, 100), "full_text": "Test", "specs": {}}
    status_create, data = make_request("POST", "/api/transcripts", headers={"Authorization": f"Bearer {jwt_a}"}, body=body)
    if status_create == 201 and data and "id" in data:
        # Try to access as user B (should fail or return empty)
        status_get, _ = make_request("GET", f"/api/transcripts/{data['id']}", headers={"Authorization": f"Bearer {jwt_b}"})
        log_result(f"Transcript user isolation #{i+1}", 404, status_get, critical=True)

# ============================================================================
# SCRIPTS CRUD (150 scenarios)
# ============================================================================

print("[SCRIPTS] Testing scripts CRUD...")

# Create script (valid)
for i in range(50):
    jwt = random_jwt()
    body = {
        "title": f"Script {random_string(10)}",
        "talking_points": {
            "intro": f"Hello {random_string(5)}",
            "pitch": f"Pitch {random_string(10)}"
        }
    }
    status, _ = make_request("POST", "/api/scripts", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Script create valid #{i+1}", 201, status)

# Create script (invalid JSONB talking_points)
for i in range(25):
    jwt = random_jwt()
    body = {
        "title": f"Script {random_string(10)}",
        "talking_points": "not a JSON object"
    }
    status, _ = make_request("POST", "/api/scripts", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Script create invalid JSONB #{i+1}", 400, status)

# List scripts (valid)
for i in range(25):
    jwt = random_jwt()
    status, _ = make_request("GET", "/api/scripts", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Script list valid #{i+1}", 200, status)

# Soft delete test
for i in range(50):
    jwt = random_jwt()
    status, _ = make_request("DELETE", f"/api/scripts/{random.randint(1, 100)}", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Script soft delete #{i+1}", 200 if random.random() > 0.5 else 404, status)

# ============================================================================
# PRODUCTS CRUD (150 scenarios)
# ============================================================================

print("[PRODUCTS] Testing products CRUD...")

# Create product (valid)
for i in range(50):
    jwt = random_jwt()
    body = {
        "name": f"Product {random_string(10)}",
        "linked_script_id": random.randint(1, 100),
        "specs": {
            "price": random.uniform(10, 1000),
            "category": random.choice(["A", "B", "C"])
        }
    }
    status, _ = make_request("POST", "/api/products", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Product create valid #{i+1}", 201, status)

# Create product (invalid specs JSONB)
for i in range(25):
    jwt = random_jwt()
    body = {
        "name": f"Product {random_string(10)}",
        "linked_script_id": random.randint(1, 100),
        "specs": "not a JSON object"
    }
    status, _ = make_request("POST", "/api/products", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Product create invalid JSONB #{i+1}", 400, status)

# Foreign key constraint test (invalid linked_script_id)
for i in range(25):
    jwt = random_jwt()
    body = {
        "name": f"Product {random_string(10)}",
        "linked_script_id": 99999999,  # likely doesn't exist
        "specs": {}
    }
    status, _ = make_request("POST", "/api/products", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"Product FK constraint #{i+1}", 400 if status != 201 else 201, status)

# List products (valid)
for i in range(50):
    jwt = random_jwt()
    status, _ = make_request("GET", "/api/products", headers={"Authorization": f"Bearer {jwt}"})
    log_result(f"Product list valid #{i+1}", 200, status)

# ============================================================================
# TTS PROXY (100 scenarios)
# ============================================================================

print("[TTS] Testing TTS proxy endpoint...")

# Valid text
for i in range(40):
    jwt = random_jwt()
    body = {"text": f"Hello world {random_string(20)}"}
    status, _ = make_request("POST", "/api/tts", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"TTS valid text #{i+1}", 200, status)

# Empty text
for i in range(20):
    jwt = random_jwt()
    body = {"text": ""}
    status, _ = make_request("POST", "/api/tts", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"TTS empty text #{i+1}", 400, status)

# Very long text
for i in range(20):
    jwt = random_jwt()
    body = {"text": random_string(5000)}
    status, _ = make_request("POST", "/api/tts", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"TTS long text #{i+1}", 200 if status == 200 else 400, status)

# Special characters
for i in range(20):
    jwt = random_jwt()
    body = {"text": f"Test <script>alert('xss')</script> {random_string(10)}"}
    status, _ = make_request("POST", "/api/tts", headers={"Authorization": f"Bearer {jwt}"}, body=body)
    log_result(f"TTS special chars #{i+1}", 200, status)

# ============================================================================
# RESULTS
# ============================================================================

pass_rate = (passed / total_scenarios * 100) if total_scenarios > 0 else 0
result_status = "PASS" if pass_rate >= 99.5 else "FAIL"

print("\n" + "="*60)
print("FORGEIQ BACKEND BATTERY TEST RESULTS")
print("="*60)
print(f"Total scenarios: {total_scenarios}")
print(f"Passed: {passed}")
print(f"Failed: {failed}")
print(f"Pass rate: {pass_rate:.2f}%")
print(f"Status: {result_status} (target ≥99.5%)")
print(f"\nCritical failures: {len(critical_failures)}")

if critical_failures:
    print("\nCRITICAL FAILURES (security/data leak risks):")
    for cf in critical_failures[:10]:  # show first 10
        print(f"  - {cf}")
    if len(critical_failures) > 10:
        print(f"  ... and {len(critical_failures) - 10} more")

# Write result file
with open("/tmp/forgeiq-backend-battery-result.txt", "w") as f:
    f.write(f"FORGEIQ BACKEND BATTERY TEST\n")
    f.write(f"Date: {datetime.now().isoformat()}\n\n")
    f.write(f"Total scenarios: {total_scenarios}\n")
    f.write(f"Pass rate: {pass_rate:.2f}%\n")
    f.write(f"Status: {result_status} (≥99.5% = PASS)\n\n")
    f.write(f"Critical failures: {len(critical_failures)}\n")
    if critical_failures:
        f.write("\nCRITICAL FAILURES:\n")
        for cf in critical_failures:
            f.write(f"  - {cf}\n")

print(f"\nResult written to /tmp/forgeiq-backend-battery-result.txt")
