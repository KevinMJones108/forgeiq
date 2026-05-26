# Auth0 Setup Guide — ForgeIQ

## Two Options

**Option A:** Run automated script (recommended)
```bash
cd ~/qbo/forgeiq/forgeiq-api
./setup-auth0.sh
```

**Option B:** Manual setup (if script fails or you prefer dashboard control)

---

## Manual Setup Steps

### 1. Create Auth0 Tenant

1. Go to https://manage.auth0.com/dashboard
2. Click **Create Tenant**
3. **Tenant name:** `forgeiq` (or your choice)
4. **Region:** US (or nearest)
5. **Environment:** Development (change to Production later)
6. Click **Create**

**Save your tenant domain** (e.g., `forgeiq.auth0.com` or `forgeiq.us.auth0.com`)

---

### 2. Create API

1. In Auth0 dashboard, go to **Applications > APIs**
2. Click **Create API**
3. **Name:** `ForgeIQ API`
4. **Identifier:** `https://forgeiq-api.onrender.com`
5. **Signing Algorithm:** `RS256`
6. Click **Create**

**Save the Identifier** (this is your Auth0 Audience)

---

### 3. Create iOS Application

1. Go to **Applications > Applications**
2. Click **Create Application**
3. **Name:** `ForgeIQ iOS`
4. **Type:** Native
5. Click **Create**
6. After creation, go to **Settings** tab
7. **Allowed Callback URLs:**
   ```
   ai.alviz.forgeiq://YOUR-DOMAIN.auth0.com/ios/ai.alviz.forgeiq/callback
   ```
   Replace `YOUR-DOMAIN` with your tenant domain (e.g., `forgeiq`)

8. **Allowed Logout URLs:**
   ```
   ai.alviz.forgeiq://YOUR-DOMAIN.auth0.com/ios/ai.alviz.forgeiq/callback
   ```

9. Click **Save Changes**

**Save your Client ID** (found in Basic Information section)

---

### 4. Update iOS Constants.swift

Edit: `~/qbo/forgeiq/ForgeIQ/Shared/Constants.swift`

```swift
// Auth0 Configuration
static let AUTH0_DOMAIN = "YOUR-TENANT.auth0.com"
static let AUTH0_CLIENT_ID = "YOUR-CLIENT-ID"
static let AUTH0_AUDIENCE = "https://forgeiq-api.onrender.com"
```

Replace:
- `YOUR-TENANT` with your tenant domain
- `YOUR-CLIENT-ID` with iOS app Client ID

---

### 5. Update Backend .env

Edit: `~/qbo/forgeiq/forgeiq-api/.env`

Add or update:
```bash
AUTH0_DOMAIN=YOUR-TENANT.auth0.com
AUTH0_AUDIENCE=https://forgeiq-api.onrender.com
AUTH0_CLIENT_ID=YOUR-CLIENT-ID
```

---

### 6. Test Auth Middleware

Start the Node.js server:
```bash
cd ~/qbo/forgeiq/forgeiq-api
npm install
node src/server.js
```

In another terminal:
```bash
# Health check (no auth)
curl http://localhost:3001/health

# Protected endpoint (should return 401)
curl http://localhost:3001/api/v1/auth/me
```

Expected:
- Health check returns `{"status":"ok"}`
- Protected endpoint returns 401 (Unauthorized)

---

## Verification Checklist

- [ ] Tenant created in Auth0 dashboard
- [ ] API created with identifier `https://forgeiq-api.onrender.com`
- [ ] iOS app created with correct callback URLs
- [ ] Constants.swift updated with Auth0 values
- [ ] .env updated with Auth0 values
- [ ] Health endpoint returns 200
- [ ] Protected endpoint returns 401 without token

---

## Troubleshooting

### "Invalid domain format"
Ensure domain is: `tenant.auth0.com` or `tenant.us.auth0.com`

### "Client ID format unusual"
Auth0 Client IDs are 32 alphanumeric characters. If yours differs, it may still work — continue with warning.

### "Health check failed"
- Ensure Node.js server is running: `node src/server.js`
- Check port 3001 is not in use: `lsof -i :3001`
- Check .env file exists with valid values

### "401 on all endpoints"
This is correct for protected endpoints without a token.
Use iOS app login flow to get a valid JWT.

---

## Next Steps

1. **Build iOS app in Xcode** to test login flow
2. **Deploy backend to Render** with Auth0 env vars
3. **Test full auth flow on device**

Auth0 dashboard: https://manage.auth0.com/dashboard

---

## Auth0 Documentation

- [Auth0 iOS Quickstart](https://auth0.com/docs/quickstart/native/ios-swift)
- [Auth0 Node.js API](https://auth0.com/docs/quickstart/backend/nodejs)
- [JWT Validation](https://auth0.com/docs/secure/tokens/json-web-tokens/validate-json-web-tokens)

---

## Security Notes

- **Never commit .env** — already in .gitignore
- **Client ID is public** — safe to hardcode in iOS Constants.swift
- **API keys stay server-side** — ELEVEN_LABS_API_KEY, ANTHROPIC_API_KEY in .env only
- **Use RS256** — not HS256 (symmetric keys)
- **Rotate secrets** if exposed in logs or commits
