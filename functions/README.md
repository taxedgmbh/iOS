# Taxed GmbH - Firebase Cloud Functions

AI-powered document processing for Swiss tax documents using OpenAI GPT-4 Vision.

## Overview

When a customer uploads a tax document via the iOS app:
1. Document is uploaded to Firebase Storage (`documents/{customerId}/{filename}`)
2. Cloud Function automatically triggers
3. Document is sent to OpenAI GPT-4 Vision for OCR + classification
4. Results are saved to Firestore (`documents/{documentId}`)
5. Customer sees the classified document in real-time

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Set OpenAI API Key

Create a `.env` file (copy from `.env.example`):

```bash
cp .env.example .env
```

Edit `.env` and add your OpenAI API key:

```
OPENAI_API_KEY=sk-your-actual-api-key-here
```

Get your API key from: https://platform.openai.com/api-keys

### 3. Configure Firebase (if not already done)

```bash
# Login to Firebase
firebase login

# Initialize functions (if not already initialized)
firebase init functions
# Select TypeScript
# Select your project: taxedgmbh
```

### 4. Set Environment Variables in Firebase

For production deployment, set the environment variable:

```bash
firebase functions:config:set openai.key="sk-your-actual-api-key-here"
```

## Development

### Run Locally with Emulator

```bash
npm run serve
```

This starts the Firebase emulator with your functions.

### Build TypeScript

```bash
npm run build
```

### Test Locally

```bash
npm run shell
```

## Deployment

### Deploy to Firebase

```bash
npm run deploy
```

Or using Firebase CLI directly:

```bash
firebase deploy --only functions
```

### Deploy Specific Function

```bash
firebase deploy --only functions:onDocumentUpload
```

## Function Details

### `onDocumentUpload`

**Trigger**: Firebase Storage object finalize (file upload complete)
**Path**: `documents/{customerId}/{fileName}`

**Process**:
1. Validates file is an image in `documents/` folder
2. Finds corresponding Firestore document (by filename + status="processing")
3. Downloads image from Storage
4. Sends to OpenAI GPT-4 Vision API
5. Parses AI response (category, subcategory, confidence, summary, amount)
6. Updates Firestore document with results
7. Sets status to "pending" for expert review

**Environment Variables**:
- `OPENAI_API_KEY` - OpenAI API key for GPT-4 Vision

**Error Handling**:
- If AI processing fails, document status is set to "pending" with error note
- Expert can still review manually

## Document Categories

The AI classifies Swiss tax documents into:

### Income (Einkommen)
- Salary certificates (Lohnausweis)
- Freelance invoices (Honorarnoten)
- Investment income (Kapitalerträge)
- Dividends

### Deduction (Abzüge)
- Professional expenses (Berufsauslagen)
- Charitable donations (Spenden)
- Medical expenses (Krankheitskosten)
- Education costs (Weiterbildung)

### Pillar (Säule 2/3)
- Pillar 2 (BVG - occupational pension)
- Pillar 3a (tax-privileged retirement savings)
- Pillar 3b (flexible retirement savings)

### Wealth (Vermögen)
- Property (Immobilien)
- Securities (Wertschriften)
- Bank accounts (Bankkonten)

## Costs

**OpenAI GPT-4 Vision API**:
- ~$0.01 - $0.03 per document (depending on image size)
- 100 documents = ~$1-3
- 1,000 documents = ~$10-30

**Firebase Functions**:
- Free tier: 2 million invocations/month
- Paid tier: $0.40 per million invocations

**Total estimated cost**: ~$10-50/month for 1,000 documents

## Monitoring

### View Logs

```bash
npm run logs
```

Or in Firebase Console:
https://console.firebase.google.com/project/taxedgmbh/functions

### Check Function Execution

```bash
firebase functions:log --only onDocumentUpload
```

## Troubleshooting

### Function not triggering

1. Check that Storage rules allow uploads:
   ```
   // In Firebase Console → Storage → Rules
   match /documents/{customerId}/{fileName} {
     allow write: if request.auth != null && request.auth.uid == customerId;
   }
   ```

2. Check Firestore document has `status: "processing"` when uploaded

3. Check filename matches between Storage and Firestore

### AI classification failing

1. Verify `OPENAI_API_KEY` is set correctly
2. Check OpenAI API credits: https://platform.openai.com/usage
3. Check logs for error messages

### Function timeout

1. Increase timeout in `firebase.json` (max 540s for paid plan)
2. Reduce image size before upload (recommend max 2MB)

## Security

- ✅ API keys stored as environment variables (not in code)
- ✅ Storage rules restrict uploads to authenticated users only
- ✅ Firestore rules restrict access to document owners
- ✅ No sensitive data logged to console

## Support

For issues or questions, contact the development team.
